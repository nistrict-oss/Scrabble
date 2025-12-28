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

	WinsLeaderboard = {} :: { LeaderboardEntry },
	WordsLeaderboard = {} :: { LeaderboardEntry },
	PointsLeaderboard = {} :: { LeaderboardEntry },

	-- Track if we've received valid data
	HasReceivedData = false,

	OnLeaderboardsUpdated = Signal.new(),
}

export type LeaderboardServiceClient = typeof(LeaderboardServiceClient)

function LeaderboardServiceClient.init(self: LeaderboardServiceClient)
	self.Networker = Networker.client.new("LeaderboardService", self)

	-- Request initial data with retry logic (after player is loaded)
	task.spawn(function()
		-- Wait for the local player to exist
		local player = Players.LocalPlayer
		if not player then
			player = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
			player = Players.LocalPlayer
		end

		print("[LeaderboardService] Starting fetch loop for player:", player.Name)

		-- Removed Character wait as it blocks UI loading if no character is present

		local maxRetries = 10
		local retryDelay = 2

		for i = 1, maxRetries do
			print("[LeaderboardService] Requesting leaderboards (Attempt " .. i .. ")")
			self.Networker:fire("GetLeaderboards")

			-- Wait for response
			task.wait(retryDelay)

			-- Check if we got valid data
			if self.HasReceivedData then
				print("[LeaderboardService] Received data, stopping loop")
				break
			end

			-- Increase delay for next retry
			retryDelay = math.min(retryDelay * 1.5, 10)
		end
	end)
end

function LeaderboardServiceClient.LeaderboardsUpdated(
	self: LeaderboardServiceClient,
	wins: { LeaderboardEntry },
	words: { LeaderboardEntry },
	points: { LeaderboardEntry }
)
	print("[LeaderboardService] Client received update with", #wins, "wins", #words, "words", #points, "points")
	self.WinsLeaderboard = wins or {}
	self.WordsLeaderboard = words or {}
	self.PointsLeaderboard = points or {}

	-- Mark as received since we got a valid response from server
	self.HasReceivedData = true

	self.OnLeaderboardsUpdated:Fire(self.WinsLeaderboard, self.WordsLeaderboard, self.PointsLeaderboard)
end

function LeaderboardServiceClient.getWinsLeaderboard(self: LeaderboardServiceClient): { LeaderboardEntry }
	return self.WinsLeaderboard
end

function LeaderboardServiceClient.getWordsLeaderboard(self: LeaderboardServiceClient): { LeaderboardEntry }
	return self.WordsLeaderboard
end

function LeaderboardServiceClient.getPointsLeaderboard(self: LeaderboardServiceClient): { LeaderboardEntry }
	return self.PointsLeaderboard
end

return LeaderboardServiceClient
