local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)
local DataService = require(ReplicatedStorage.Packages.DataService).server
local Purchases = require(ReplicatedStorage.Shared.Modules.Game.Purchases)

-- Lazy-loaded analytics
local AnalyticsService
task.defer(function()
	AnalyticsService = require(ServerScriptService.Services.AnalyticsService.AnalyticsServiceServer)
end)

-- Maximum allowed price level difference for gifting/trading (0-1000 scale)
-- Lower = stricter, higher = more lenient
-- 200 = allow ~20% price difference between users
local MAX_PRICE_LEVEL_DIFFERENCE = 200

local PurchaseServiceServer = {
	Networker = nil,
	CurrencyService = nil,
	LeaderboardService = nil, -- Lazy-loaded for donation handling
	
	GamepassCache = {}, -- { [Player] = { [gamepassName] = true } }
	GamepassLoadedFlags = {}, -- { [Player] = true } - tracks if gamepasses finished loading
	PriceLevelCache = {}, -- { [UserId] = priceLevel }
	PricesCache = {     -- Fetched from MarketplaceService
		Gamepasses = {}, -- { [gamepassName] = price }
		Products = {},   -- { [productName] = price }
	},
	PricesFetched = false,
	
	-- Pending gifts: tracks who should receive the item when purchase completes
	-- { [buyerUserId] = { type = "gamepass"|"product", itemName = string, recipientUserId = number } }
	PendingGifts = {},
	
	OnGamepassPurchased = Signal.new(),
	OnProductPurchased = Signal.new(),
}

export type PurchaseServiceServer = typeof(PurchaseServiceServer) & {
	Networker: Networker.Server,
}

function PurchaseServiceServer.init(self: PurchaseServiceServer)
	task.defer(function()
		self.CurrencyService = require(ServerScriptService.Services.CurrencyService.CurrencyServiceServer)
		self.LeaderboardService = require(ServerScriptService.Services.LeaderboardService.LeaderboardServiceServer)
	end)
	
	self.Networker = Networker.server.new("PurchaseService", self, {
		self.PromptGamepass,
		self.PromptProduct,
		self.PromptGiftGamepass,
		self.PromptGiftProduct,
		self.GetOwnedGamepasses,
		self.GetPrices,
	})
	
	-- Fetch prices from MarketplaceService
	task.spawn(function()
		self:fetchAllPrices()
	end)
	
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
		if wasPurchased then
			self:onGamepassPurchased(player, gamepassId)
		else
			-- Purchase was cancelled - clear any pending gift
			if self.PendingGifts[player.UserId] and self.PendingGifts[player.UserId].type == "gamepass" then
				self.PendingGifts[player.UserId] = nil
			end
		end
	end)
	
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return self:processReceipt(receiptInfo)
	end
	
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			self:loadGamepasses(player)
		end)
	end
	
	Players.PlayerAdded:Connect(function(player)
		self:loadGamepasses(player)
		-- Cache player's price level for gifting/trading protection
		task.spawn(function()
			self:getUserPriceLevel(player)
		end)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self.GamepassCache[player] = nil
		self.GamepassLoadedFlags[player] = nil
		self.PriceLevelCache[player.UserId] = nil
		self.PendingGifts[player.UserId] = nil -- Clear any pending gifts
	end)
	
	-- Preload price levels for existing players
	task.spawn(function()
		self:preloadPriceLevels()
	end)
end

-- Fetch prices from MarketplaceService for all gamepasses and products
function PurchaseServiceServer.fetchAllPrices(self: PurchaseServiceServer)
	print("[PurchaseService] Fetching prices from MarketplaceService...")
	
	-- Fetch gamepass prices
	for gamepassName, gamepass in Purchases.GAMEPASSES do
		if gamepass.robloxId > 0 then
			local success, info = pcall(function()
				return MarketplaceService:GetProductInfo(gamepass.robloxId, Enum.InfoType.GamePass)
			end)
			
			if success and info then
				self.PricesCache.Gamepasses[gamepassName] = info.PriceInRobux or 0
			else
				warn("[PurchaseService] Failed to fetch price for gamepass:", gamepassName)
				self.PricesCache.Gamepasses[gamepassName] = gamepass.price -- Fallback to configured price
			end
		else
			self.PricesCache.Gamepasses[gamepassName] = gamepass.price -- Use configured price if no ID
		end
	end
	
	-- Fetch product prices
	for productName, product in Purchases.PRODUCTS do
		if product.robloxId > 0 then
			local success, info = pcall(function()
				return MarketplaceService:GetProductInfo(product.robloxId, Enum.InfoType.Product)
			end)
			
			if success and info then
				self.PricesCache.Products[productName] = info.PriceInRobux or 0
			else
				warn("[PurchaseService] Failed to fetch price for product:", productName)
				self.PricesCache.Products[productName] = product.price -- Fallback to configured price
			end
		else
			self.PricesCache.Products[productName] = product.price -- Use configured price if no ID
		end
	end
	
	self.PricesFetched = true
	print("[PurchaseService] Prices fetched successfully!")
end

-- Network handler: Send prices to requesting client
function PurchaseServiceServer.GetPrices(self: PurchaseServiceServer, player: Player)
	self.Networker:fire({ player }, "PricesLoaded", self.PricesCache.Gamepasses, self.PricesCache.Products)
end

function PurchaseServiceServer.loadGamepasses(self: PurchaseServiceServer, player: Player)
	self.GamepassCache[player] = {}
	self.GamepassLoadedFlags[player] = false
	
	-- Check ownership for each gamepass via MarketplaceService
	for gamepassName, gamepass in Purchases.GAMEPASSES do
		local robloxId = gamepass.robloxId
		if robloxId > 0 then
			-- Retry up to 3 times if API fails
			for attempt = 1, 3 do
				local success, owns = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, robloxId)
				end)
				
				if success then
					if owns then
						self.GamepassCache[player][gamepassName] = true
					end
					break
				else
					if attempt < 3 then
						task.wait(0.5) -- Wait before retry
					else
						warn("[PurchaseService] Failed to check ownership for", gamepassName, "after 3 attempts")
					end
				end
			end
		end
	end
	
	-- Also load from saved data (for testing/admin purposes)
	if DataService:hasProfile(player) then
		local gamepasses = DataService:get(player, { "Gamepasses" }) or {}
		for gamepassName in gamepasses do
			self.GamepassCache[player][gamepassName] = true
		end
	end
	
	-- Mark as loaded
	self.GamepassLoadedFlags[player] = true
	
	-- Send owned gamepass names to client
	self:sendOwnedGamepasses(player)
end

-- Helper to send owned gamepasses to a player
function PurchaseServiceServer.sendOwnedGamepasses(self: PurchaseServiceServer, player: Player)
	local ownedList = {}
	for gamepassName in self.GamepassCache[player] or {} do
		table.insert(ownedList, gamepassName)
	end
	self.Networker:fire({ player }, "GamepassesLoaded", ownedList)
end

function PurchaseServiceServer.ownsGamepass(self: PurchaseServiceServer, player: Player, gamepassName: string): boolean
	return self.GamepassCache[player] and self.GamepassCache[player][gamepassName] == true
end

function PurchaseServiceServer.onGamepassPurchased(self: PurchaseServiceServer, player: Player, robloxId: number)
	-- Find the gamepass name by Roblox ID
	local gamepassName, _ = Purchases.findGamepassByRobloxId(robloxId)
	if not gamepassName then
		warn("Unknown gamepass purchased with ID:", robloxId)
		return
	end
	
	-- Check if this was a gift purchase
	local pendingGift = self.PendingGifts[player.UserId]
	local targetPlayer = player
	
	if pendingGift and pendingGift.type == "gamepass" and pendingGift.itemName == gamepassName then
		-- This was a gift - give to recipient instead
		local recipient = Players:GetPlayerByUserId(pendingGift.recipientUserId)
		if recipient then
			targetPlayer = recipient
			print("[PurchaseService] Gift gamepass:", gamepassName, "from", player.Name, "to", recipient.Name)
		else
			-- Recipient left the game - still grant to buyer as fallback
			warn("[PurchaseService] Gift recipient left game, granting to buyer instead")
		end
		-- Clear pending gift
		self.PendingGifts[player.UserId] = nil
	end
	
	if not self.GamepassCache[targetPlayer] then
		self.GamepassCache[targetPlayer] = {}
	end
	self.GamepassCache[targetPlayer][gamepassName] = true
	
	-- Save to target player's data
	if DataService:hasProfile(targetPlayer) then
		local gamepasses = DataService:get(targetPlayer, { "Gamepasses" }) or {}
		gamepasses[gamepassName] = true
		DataService:set(targetPlayer, { "Gamepasses" }, gamepasses)
	end
	
	self.OnGamepassPurchased:Fire(targetPlayer, robloxId, gamepassName)
	self.Networker:fire({ targetPlayer }, "GamepassPurchased", robloxId, gamepassName)
	
	-- Track purchase
	if AnalyticsService then
		local price = self.PricesCache.Gamepasses[gamepassName] or 0
		AnalyticsService:trackPurchaseCompleted(player, "gamepass", gamepassName, price)
	end
	
	-- If it was a gift, notify the buyer too
	if targetPlayer ~= player then
		self.Networker:fire({ player }, "GiftSent", gamepassName, targetPlayer.DisplayName)
	end
end

function PurchaseServiceServer.processReceipt(self: PurchaseServiceServer, receiptInfo): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	local robloxId = receiptInfo.ProductId
	
	-- Check if this is a donation product
	if self.LeaderboardService and self.LeaderboardService:isDonationProduct(robloxId) then
		local donationValue = self.LeaderboardService:getDonationValue(robloxId)
		self.LeaderboardService:recordDonation(player, robloxId)
		self.Networker:fire({ player }, "DonationReceived", robloxId, donationValue)
		
		-- Track donation
		if AnalyticsService then
			AnalyticsService:trackDonation(player, donationValue)
			AnalyticsService:trackPurchaseCompleted(player, "donation", tostring(robloxId), donationValue)
		end
		
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
	local productName, product = Purchases.findProductByRobloxId(robloxId)
	
	if productName and product then
		-- Check if this was a gift purchase
		local pendingGift = self.PendingGifts[player.UserId]
		local targetPlayer = player
		
		if pendingGift and pendingGift.type == "product" and pendingGift.itemName == productName then
			-- This was a gift - give to recipient instead
			local recipient = Players:GetPlayerByUserId(pendingGift.recipientUserId)
			if recipient then
				targetPlayer = recipient
				print("[PurchaseService] Gift product:", productName, "from", player.Name, "to", recipient.Name)
			else
				-- Recipient left the game - still grant to buyer as fallback
				warn("[PurchaseService] Gift recipient left game, granting to buyer instead")
			end
			-- Clear pending gift
			self.PendingGifts[player.UserId] = nil
		end
		
		-- Handle cash products
		if product.cash and self.CurrencyService then
			-- Note: VIP multiplier does NOT apply to purchased cash (only in-game earnings)
			self.CurrencyService:addCash(targetPlayer, product.cash, "product_" .. productName)
		end
		
		-- Note: Slot unlock products are handled by InventoryService listening to OnProductPurchased
		-- Pass the target player so it unlocks for the right person
		
		self.OnProductPurchased:Fire(targetPlayer, robloxId, productName)
		self.Networker:fire({ targetPlayer }, "ProductPurchased", robloxId, productName)
		
		-- Track purchase
		if AnalyticsService then
			local price = self.PricesCache.Products[productName] or 0
			AnalyticsService:trackPurchaseCompleted(player, "devproduct", productName, price)
		end
		
		-- If it was a gift, notify the buyer too
		if targetPlayer ~= player then
			self.Networker:fire({ player }, "GiftSent", productName, targetPlayer.DisplayName)
		end
		
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- ========== GAMEPASS BENEFIT CHECKS ==========

-- Supporter: 2x cash from IN-GAME earnings (wins, tasks, etc.) - NOT purchased cash
function PurchaseServiceServer.getCashMultiplier(self: PurchaseServiceServer, player: Player): number
	if self:ownsGamepass(player, "Supporter") then
		return 2
	end
	return 1
end

-- Check if player is a Supporter (for chat tags, etc.)
function PurchaseServiceServer.isSupporter(self: PurchaseServiceServer, player: Player): boolean
	return self:ownsGamepass(player, "Supporter")
end

-- ExtraLife: Start with 3 lives instead of 2
function PurchaseServiceServer.getStartingLives(self: PurchaseServiceServer, player: Player): number
	if self:ownsGamepass(player, "ExtraLife") then
		return 3
	end
	return 2
end

-- InstantSpin: Skip spin animation, instantly show result
function PurchaseServiceServer.hasInstantSpin(self: PurchaseServiceServer, player: Player): boolean
	return self:ownsGamepass(player, "InstantSpin")
end

-- LuckySpins: 2x chance for Rare+ styles
function PurchaseServiceServer.hasLuckySpins(self: PurchaseServiceServer, player: Player): boolean
	return self:ownsGamepass(player, "LuckySpins")
end

function PurchaseServiceServer.PromptGamepass(_self: PurchaseServiceServer, player: Player, gamepassName: string)
	local robloxId = Purchases.getGamepassRobloxId(gamepassName)
	if robloxId > 0 then
		MarketplaceService:PromptGamePassPurchase(player, robloxId)
	end
end

function PurchaseServiceServer.PromptProduct(_self: PurchaseServiceServer, player: Player, productName: string)
	local robloxId = Purchases.getProductRobloxId(productName)
	if robloxId > 0 then
		MarketplaceService:PromptProductPurchase(player, robloxId)
	end
end

function PurchaseServiceServer.PromptGiftGamepass(self: PurchaseServiceServer, player: Player, gamepassName: string, recipientUserId: number)
	-- Find recipient player
	local recipient = Players:GetPlayerByUserId(recipientUserId)
	if not recipient then
		self.Networker:fire({ player }, "PurchaseFailed", "Recipient not found in game")
		return
	end
	
	-- Check price level compatibility
	local canGift, reason = self:canGiftBetweenUsers(player, recipient)
	if not canGift then
		self.Networker:fire({ player }, "PurchaseFailed", reason or "Cannot gift to this player")
		return
	end
	
	-- Check if recipient already owns it
	if self:ownsGamepass(recipient, gamepassName) then
		self.Networker:fire({ player }, "PurchaseFailed", "Player already owns this gamepass")
		return
	end
	
	local robloxId = Purchases.getGamepassRobloxId(gamepassName)
	if robloxId > 0 then
		-- Store pending gift so we know to give to recipient when purchase completes
		self.PendingGifts[player.UserId] = {
			type = "gamepass",
			itemName = gamepassName,
			recipientUserId = recipientUserId,
		}
		
		-- Prompt the purchase
		MarketplaceService:PromptGamePassPurchase(player, robloxId)
	end
end

function PurchaseServiceServer.PromptGiftProduct(self: PurchaseServiceServer, player: Player, productName: string, recipientUserId: number)
	-- Find recipient player
	local recipient = Players:GetPlayerByUserId(recipientUserId)
	if not recipient then
		self.Networker:fire({ player }, "PurchaseFailed", "Recipient not found in game")
		return
	end
	
	-- Check price level compatibility
	local canGift, reason = self:canGiftBetweenUsers(player, recipient)
	if not canGift then
		self.Networker:fire({ player }, "PurchaseFailed", reason or "Cannot gift to this player")
		return
	end
	
	local robloxId = Purchases.getProductRobloxId(productName)
	if robloxId > 0 then
		-- Store pending gift so we know to give to recipient when purchase completes
		self.PendingGifts[player.UserId] = {
			type = "product",
			itemName = productName,
			recipientUserId = recipientUserId,
		}
		
		-- Prompt the purchase
		MarketplaceService:PromptProductPurchase(player, robloxId)
	end
end

function PurchaseServiceServer.GetOwnedGamepasses(self: PurchaseServiceServer, player: Player)
	-- Wait for gamepasses to finish loading (max 5 seconds)
	local waited = 0
	while not self.GamepassLoadedFlags[player] and waited < 5 do
		task.wait(0.1)
		waited += 0.1
	end
	
	-- If still not loaded, trigger a fresh load
	if not self.GamepassLoadedFlags[player] then
		self:loadGamepasses(player)
	else
		-- Just send the cached data
		self:sendOwnedGamepasses(player)
	end
end

-- ========== PRICE LEVEL / REGIONAL PRICING ==========
-- Used to protect trades and gifts from price arbitrage

-- Get price levels for multiple users (cached)
function PurchaseServiceServer.getUserPriceLevels(self: PurchaseServiceServer, userIds: { number }): { [number]: number }
	local uncachedIds = {}
	local results = {}
	
	-- Check cache first
	for _, userId in userIds do
		if self.PriceLevelCache[userId] then
			results[userId] = self.PriceLevelCache[userId]
		else
			table.insert(uncachedIds, userId)
		end
	end
	
	-- Fetch uncached price levels
	if #uncachedIds > 0 then
		local success, priceLevels = pcall(function()
			return MarketplaceService:GetUsersPriceLevelsAsync(uncachedIds)
		end)
		
		if success and priceLevels then
			for userId, level in priceLevels do
				self.PriceLevelCache[userId] = level
				results[userId] = level
			end
		else
			-- Default to max price level (1000) if API fails
			warn("[PurchaseService] Failed to fetch price levels, defaulting to 1000")
			for _, userId in uncachedIds do
				self.PriceLevelCache[userId] = 1000
				results[userId] = 1000
			end
		end
	end
	
	return results
end

-- Get single user's price level
function PurchaseServiceServer.getUserPriceLevel(self: PurchaseServiceServer, player: Player): number
	local levels = self:getUserPriceLevels({ player.UserId })
	return levels[player.UserId] or 1000
end

-- Check if gifting/trading is allowed between two users based on price levels
function PurchaseServiceServer.canGiftBetweenUsers(self: PurchaseServiceServer, fromPlayer: Player, toPlayer: Player): (boolean, string?)
	local levels = self:getUserPriceLevels({ fromPlayer.UserId, toPlayer.UserId })
	
	local fromLevel = levels[fromPlayer.UserId] or 1000
	local toLevel = levels[toPlayer.UserId] or 1000
	
	local difference = math.abs(fromLevel - toLevel)
	
	if difference > MAX_PRICE_LEVEL_DIFFERENCE then
		return false, string.format(
			"Regional pricing difference too large (%d). Maximum allowed: %d",
			difference,
			MAX_PRICE_LEVEL_DIFFERENCE
		)
	end
	
	return true, nil
end

-- Preload price levels for all players in the game (call on init)
function PurchaseServiceServer.preloadPriceLevels(self: PurchaseServiceServer)
	local userIds = {}
	for _, player in Players:GetPlayers() do
		table.insert(userIds, player.UserId)
	end
	
	if #userIds > 0 then
		task.spawn(function()
			self:getUserPriceLevels(userIds)
			print("[PurchaseService] Preloaded price levels for", #userIds, "players")
		end)
	end
end

-- Re-export Purchases module for convenience
PurchaseServiceServer.Purchases = Purchases

-- Export the max difference constant for other services to reference
PurchaseServiceServer.MAX_PRICE_LEVEL_DIFFERENCE = MAX_PRICE_LEVEL_DIFFERENCE

return PurchaseServiceServer
