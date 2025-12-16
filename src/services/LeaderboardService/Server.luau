--[[
	LeaderboardService/Server.luau
	
	Manages global leaderboards for wins, eliminations, streaks, and donations using OrderedDataStore.
	Broadcasts leaderboard data to clients for billboard display.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)
local DataService = require(ReplicatedStorage.Packages.DataService).server

-- OrderedDataStores for leaderboards
local WinsStore = DataStoreService:GetOrderedDataStore("Leaderboard_Wins_v1")
local ElimsStore = DataStoreService:GetOrderedDataStore("Leaderboard_Elims_v1")
local StreakStore = DataStoreService:GetOrderedDataStore("Leaderboard_Streak_v1")
local DonationsStore = DataStoreService:GetOrderedDataStore("Leaderboard_Donations_v1")

local LEADERBOARD_SIZE = 100 -- Top 100 players
local UPDATE_INTERVAL = 60 -- Refresh every 60 seconds
local SAVE_DEBOUNCE = 5 -- Minimum seconds between saves per player

-- Donation product IDs mapped to their Robux value
local DONATION_PRODUCTS = {
	[3477887494] = 10,
	[3477887629] = 50,
	[3477887986] = 100,
	[3477888242] = 500,
	[3477888490] = 1000,
	[3477888697] = 5000,
	[3477889116] = 10000,
}

local LeaderboardServiceServer = {
	Networker = nil :: any,
	
	-- Cached leaderboard data
	WinsLeaderboard = {} :: {{UserId: number, DisplayName: string, Value: number}},
	ElimsLeaderboard = {} :: {{UserId: number, DisplayName: string, Value: number}},
	StreakLeaderboard = {} :: {{UserId: number, DisplayName: string, Value: number}},
	DonationsLeaderboard = {} :: {{UserId: number, DisplayName: string, Value: number}},
	
	-- Track last save times to prevent spam
	LastSaveTimes = {} :: {[number]: {Wins: number, Elims: number, Streak: number, Donations: number}},
	
	-- Track if initial load is complete
	InitialLoadComplete = false,
	
	-- Signal fired when a donation is received (for other services to listen)
	OnDonationReceived = Signal.new(),
}

export type LeaderboardServiceServer = typeof(LeaderboardServiceServer)

local StatsServiceServer = nil

function LeaderboardServiceServer.init(self: LeaderboardServiceServer)
	self.Networker = Networker.server.new("LeaderboardService", self, {
		self.GetLeaderboards,
	})
	
	-- Load StatsService to listen for stat updates
	pcall(function()
		StatsServiceServer = require(ServerScriptService.Services.StatsService.StatsServiceServer)
	end)
	
	-- Listen for stat updates to save to leaderboard
	if StatsServiceServer and StatsServiceServer.OnStatUpdated then
		StatsServiceServer.OnStatUpdated:Connect(function(player: Player, statName: string, newValue: number)
			if statName == "Wins" then
				self:savePlayerScore(player, "Wins", newValue)
			elseif statName == "TotalKills" then
				self:savePlayerScore(player, "Elims", newValue)
			elseif statName == "HighestStreak" then
				self:savePlayerScore(player, "Streak", newValue)
			end
		end)
	end
	
	-- Initial fetch (do this immediately so data is ready for clients)
	task.spawn(function()
		self:refreshLeaderboards()
	end)
	
	-- Periodic refresh
	task.spawn(function()
		while true do
			task.wait(UPDATE_INTERVAL)
			self:refreshLeaderboards()
		end
	end)
	
	-- Save existing players' stats when they join
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			DataService:waitForData(player)
			if DataService:hasProfile(player) then
				local stats = DataService:get(player, { "Stats" })
				if stats then
					if stats.Wins and stats.Wins > 0 then
						self:savePlayerScore(player, "Wins", stats.Wins)
					end
					if stats.TotalKills and stats.TotalKills > 0 then
						self:savePlayerScore(player, "Elims", stats.TotalKills)
					end
					if stats.HighestStreak and stats.HighestStreak > 0 then
						self:savePlayerScore(player, "Streak", stats.HighestStreak)
					end
					if stats.TotalDonated and stats.TotalDonated > 0 then
						self:savePlayerScore(player, "Donations", stats.TotalDonated)
					end
				end
			end
		end)
	end)
end

-- Save a player's score to the appropriate OrderedDataStore
function LeaderboardServiceServer.savePlayerScore(self: LeaderboardServiceServer, player: Player, leaderboardType: string, value: number)
	if value <= 0 then return end
	
	local userId = player.UserId
	
	-- Debounce saves
	if not self.LastSaveTimes[userId] then
		self.LastSaveTimes[userId] = { Wins = 0, Elims = 0, Streak = 0, Donations = 0 }
	end
	
	local now = os.time()
	local lastSave = self.LastSaveTimes[userId][leaderboardType] or 0
	
	if now - lastSave < SAVE_DEBOUNCE then
		return
	end
	
	self.LastSaveTimes[userId][leaderboardType] = now
	
	-- Save to appropriate store
	task.spawn(function()
		local success, err = pcall(function()
			if leaderboardType == "Wins" then
				WinsStore:SetAsync(tostring(userId), value)
			elseif leaderboardType == "Elims" then
				ElimsStore:SetAsync(tostring(userId), value)
			elseif leaderboardType == "Streak" then
				StreakStore:SetAsync(tostring(userId), value)
			elseif leaderboardType == "Donations" then
				DonationsStore:SetAsync(tostring(userId), value)
			end
		end)
		
		if not success then
			warn("[LeaderboardService] Failed to save score:", err)
		end
	end)
end

-- Fetch top players from an OrderedDataStore
function LeaderboardServiceServer.fetchLeaderboard(_self: LeaderboardServiceServer, store: OrderedDataStore): {{UserId: number, DisplayName: string, Value: number}}
	local result = {}
	
	local success, pages = pcall(function()
		return store:GetSortedAsync(false, LEADERBOARD_SIZE)
	end)
	
	if not success or not pages then
		warn("[LeaderboardService] Failed to fetch leaderboard")
		return result
	end
	
	local data = pages:GetCurrentPage()
	
	for rank, entry in ipairs(data) do
		local userId = tonumber(entry.key)
		local value = entry.value
		
		if userId and value then
			-- Get display name
			local displayName = "Player"
			local nameSuccess, fetchedName = pcall(function()
				return Players:GetNameFromUserIdAsync(userId)
			end)
			if nameSuccess and fetchedName then
				displayName = fetchedName
			end
			
			table.insert(result, {
				Rank = rank,
				UserId = userId,
				DisplayName = displayName,
				Value = value,
			})
		end
	end
	
	return result
end

-- Refresh all leaderboards
function LeaderboardServiceServer.refreshLeaderboards(self: LeaderboardServiceServer)
	self.WinsLeaderboard = self:fetchLeaderboard(WinsStore)
	self.ElimsLeaderboard = self:fetchLeaderboard(ElimsStore)
	self.StreakLeaderboard = self:fetchLeaderboard(StreakStore)
	self.DonationsLeaderboard = self:fetchLeaderboard(DonationsStore)
	
	-- Mark initial load as complete
	self.InitialLoadComplete = true
	
	-- Broadcast to all connected clients
	self.Networker:fireAll("LeaderboardsUpdated", self.WinsLeaderboard, self.ElimsLeaderboard, self.StreakLeaderboard, self.DonationsLeaderboard)
end

-- Network handler: Get current leaderboards
function LeaderboardServiceServer.GetLeaderboards(self: LeaderboardServiceServer, player: Player)
	-- Wait for initial load to complete (with generous timeout for slow DataStores)
	local waitStart = os.clock()
	while not self.InitialLoadComplete and os.clock() - waitStart < 30 do
		task.wait(0.2)
	end
	
	self.Networker:fire({ player }, "LeaderboardsUpdated", self.WinsLeaderboard, self.ElimsLeaderboard, self.StreakLeaderboard, self.DonationsLeaderboard)
end

-- Check if a product ID is a donation product
function LeaderboardServiceServer.isDonationProduct(_self: LeaderboardServiceServer, productId: number): boolean
	return DONATION_PRODUCTS[productId] ~= nil
end

-- Get the Robux value of a donation product
function LeaderboardServiceServer.getDonationValue(_self: LeaderboardServiceServer, productId: number): number?
	return DONATION_PRODUCTS[productId]
end

-- Record a donation from a player
function LeaderboardServiceServer.recordDonation(self: LeaderboardServiceServer, player: Player, productId: number)
	local robuxValue = DONATION_PRODUCTS[productId]
	if not robuxValue then
		warn("[LeaderboardService] Unknown donation product:", productId)
		return
	end
	
	-- Get current total donations from player data
	local currentTotal = 0
	if DataService:hasProfile(player) then
		local stats = DataService:get(player, { "Stats" }) or {}
		currentTotal = stats.TotalDonated or 0
	end
	
	-- Add the new donation
	local newTotal = currentTotal + robuxValue
	
	-- Save to player data
	if DataService:hasProfile(player) then
		local stats = DataService:get(player, { "Stats" }) or {}
		stats.TotalDonated = newTotal
		DataService:set(player, { "Stats" }, stats)
	end
	
	-- Save to leaderboard
	self:savePlayerScore(player, "Donations", newTotal)
	
	-- Fire event for other services
	self.OnDonationReceived:Fire(player, robuxValue, newTotal)
	
	print("[LeaderboardService] Recorded donation:", player.Name, "donated", robuxValue, "R$ (total:", newTotal, ")")
end

-- Export donation products for other services to check
LeaderboardServiceServer.DONATION_PRODUCTS = DONATION_PRODUCTS

return LeaderboardServiceServer

