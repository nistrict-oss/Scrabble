--[[
	LeaderboardService/Client.luau
	
	Client-side leaderboard data storage and signals.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)

type LeaderboardEntry = {
	Rank: number,
	UserId: number,
	DisplayName: string, 
	Value: number,
}

local LeaderboardServiceClient = {
	Networker = nil :: any,
	
	WinsLeaderboard = {} :: {LeaderboardEntry},
	ElimsLeaderboard = {} :: {LeaderboardEntry},
	StreakLeaderboard = {} :: {LeaderboardEntry},
	DonationsLeaderboard = {} :: {LeaderboardEntry},
	
	-- Track if we've received valid data
	HasReceivedData = false,
	
	OnLeaderboardsUpdated = Signal.new(),
}

export type LeaderboardServiceClient = typeof(LeaderboardServiceClient)

function LeaderboardServiceClient.init(self: LeaderboardServiceClient)
	self.Networker = Networker.client.new("LeaderboardService", self)
	
	-- Request initial data with retry logic (after player is loaded)
	task.spawn(function()
		-- Wait for the local player to exist and be ready
		local player = Players.LocalPlayer
		if not player then
			player = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
			player = Players.LocalPlayer
		end
		
		-- Wait for character to load (indicates player is fully in the game)
		if not player.Character then
			player.CharacterAdded:Wait()
		end
		
		-- Small additional delay to ensure everything is stable
		task.wait(1)
		
		local maxRetries = 10
		local retryDelay = 2
		
		for _ = 1, maxRetries do
			self.Networker:fire("GetLeaderboards")
			
			-- Wait for response
			task.wait(retryDelay)
			
			-- Check if we got valid data
			if self.HasReceivedData then
				break
			end
			
			-- Increase delay for next retry
			retryDelay = math.min(retryDelay * 1.5, 10)
		end
	end)
end

function LeaderboardServiceClient.LeaderboardsUpdated(self: LeaderboardServiceClient, wins: {LeaderboardEntry}, elims: {LeaderboardEntry}, streaks: {LeaderboardEntry}, donations: {LeaderboardEntry}?)
	self.WinsLeaderboard = wins or {}
	self.ElimsLeaderboard = elims or {}
	self.StreakLeaderboard = streaks or {}
	self.DonationsLeaderboard = donations or {}
	
	-- Mark as received if we got any data
	if #self.WinsLeaderboard > 0 or #self.ElimsLeaderboard > 0 or #self.StreakLeaderboard > 0 or #self.DonationsLeaderboard > 0 then
		self.HasReceivedData = true
	end
	
	self.OnLeaderboardsUpdated:Fire(self.WinsLeaderboard, self.ElimsLeaderboard, self.StreakLeaderboard, self.DonationsLeaderboard)
end

function LeaderboardServiceClient.getWinsLeaderboard(self: LeaderboardServiceClient): {LeaderboardEntry}
	return self.WinsLeaderboard
end

function LeaderboardServiceClient.getElimsLeaderboard(self: LeaderboardServiceClient): {LeaderboardEntry}
	return self.ElimsLeaderboard
end

function LeaderboardServiceClient.getStreakLeaderboard(self: LeaderboardServiceClient): {LeaderboardEntry}
	return self.StreakLeaderboard
end

function LeaderboardServiceClient.getDonationsLeaderboard(self: LeaderboardServiceClient): {LeaderboardEntry}
	return self.DonationsLeaderboard
end

return LeaderboardServiceClient

