local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)
local DataService = require(ReplicatedStorage.Packages.DataService).server

local Codes = require(ReplicatedStorage.Shared.Modules.Game.Codes)

-- Lazy-loaded analytics
local AnalyticsService
task.defer(function()
	AnalyticsService = require(ServerScriptService.Services.AnalyticsService.AnalyticsServiceServer)
end)

local CodesServiceServer = {
	Networker = nil,
	CurrencyService = nil,
	InventoryService = nil,

	OnCodeRedeemed = Signal.new(),
}

export type CodesServiceServer = typeof(CodesServiceServer) & {
	Networker: Networker.Server,
}

function CodesServiceServer.init(self: CodesServiceServer)
	task.defer(function()
		self.CurrencyService = require(ServerScriptService.Services.CurrencyService.CurrencyServiceServer)
		self.InventoryService = require(ServerScriptService.Services.InventoryService.InventoryServiceServer)
	end)

	self.Networker = Networker.server.new("CodesService", self, {
		self.RedeemCode,
	})
end

function CodesServiceServer.hasRedeemedCode(_self: CodesServiceServer, player: Player, codeId: string): boolean
	if not DataService:hasProfile(player) then
		return true
	end -- Assume redeemed if no profile

	local redeemedCodes = DataService:get(player, { "RedeemedCodes" }) or {}
	return redeemedCodes[string.upper(codeId)] == true
end

function CodesServiceServer.markCodeRedeemed(_self: CodesServiceServer, player: Player, codeId: string)
	if not DataService:hasProfile(player) then
		return
	end

	local redeemedCodes = DataService:get(player, { "RedeemedCodes" }) or {}
	redeemedCodes[string.upper(codeId)] = true
	DataService:set(player, { "RedeemedCodes" }, redeemedCodes)
end

function CodesServiceServer.giveReward(self: CodesServiceServer, player: Player, reward: Codes.CodeReward): boolean
	if not DataService:hasProfile(player) then
		return false
	end

	if reward.type == "cash" and reward.amount then
		if self.CurrencyService then
			self.CurrencyService:addCoins(player, reward.amount, "code_redeem")
		else
			local currentCoins = DataService:get(player, { "Coins" }) or 0
			DataService:set(player, { "Coins" }, currentCoins + reward.amount)
		end
		return true
	elseif reward.type == "gun" and reward.itemId then
		local ownedGuns = DataService:get(player, { "OwnedGuns" }) or {}
		if not ownedGuns[reward.itemId] then
			ownedGuns[reward.itemId] = true
			DataService:set(player, { "OwnedGuns" }, ownedGuns)
		end
		return true
	elseif reward.type == "skin" and reward.itemId then
		local ownedSkins = DataService:get(player, { "OwnedSkins" }) or {}
		if not ownedSkins[reward.itemId] then
			ownedSkins[reward.itemId] = true
			DataService:set(player, { "OwnedSkins" }, ownedSkins)
		end
		return true
	elseif reward.type == "luckyspins" and reward.amount then
		if self.InventoryService and self.InventoryService.addLuckySpins then
			self.InventoryService:addLuckySpins(player, reward.amount)
		else
			local currentSpins = DataService:get(player, { "LuckySpins" }) or 0
			DataService:set(player, { "LuckySpins" }, currentSpins + reward.amount)
		end
		return true
	end

	return false
end

function CodesServiceServer.redeemCode(self: CodesServiceServer, player: Player, codeId: string): (boolean, string)
	if not DataService:hasProfile(player) then
		return false, "Data not loaded yet"
	end

	-- Normalize code (remove spaces and uppercase)
	local stripped = (string.gsub(codeId, "%s", ""))
	local normalizedCode = string.upper(stripped)

	-- Check if code exists and is valid
	local code = Codes.getCode(normalizedCode)
	if not code then
		return false, "Invalid code"
	end

	-- Check if already redeemed
	if self:hasRedeemedCode(player, normalizedCode) then
		return false, "Code already redeemed"
	end

	-- Give reward
	local success = self:giveReward(player, code.reward)
	if not success then
		return false, "Failed to give reward"
	end

	-- Give bonus reward if exists
	if code.bonusReward then
		self:giveReward(player, code.bonusReward)
	end

	-- Mark as redeemed
	self:markCodeRedeemed(player, normalizedCode)

	-- Fire event
	self.OnCodeRedeemed:Fire(player, normalizedCode, code.reward)

	-- Track code redemption
	if AnalyticsService then
		local rewardStr = code.reward.type .. (code.reward.amount and ("_" .. code.reward.amount) or "")
		AnalyticsService:trackCodeRedeemed(player, normalizedCode, rewardStr)
	end

	-- Generate success message
	local function getRewardText(reward: Codes.CodeReward): string
		if reward.type == "cash" then
			return "🪙 " .. (reward.amount or 0) .. " Coins"
		elseif reward.type == "gun" then
			return "🔫 " .. (reward.itemId or "Gun")
		elseif reward.type == "skin" then
			return "🎨 " .. (reward.itemId or "Skin")
		elseif reward.type == "luckyspins" then
			return "🍀 " .. (reward.amount or 0) .. " Lucky Spins"
		end
		return ""
	end

	local rewardText = getRewardText(code.reward)
	if code.bonusReward then
		rewardText = rewardText .. " + " .. getRewardText(code.bonusReward)
	end

	return true, "Redeemed: " .. rewardText
end

-- Network handler
function CodesServiceServer.RedeemCode(self: CodesServiceServer, player: Player, codeId: string)
	local success, message = self:redeemCode(player, codeId)
	self.Networker:fire({ player }, "CodeResult", success, message)
end

return CodesServiceServer
