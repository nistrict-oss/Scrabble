--[[
	useLeaderboards.luau
	
	Hook to subscribe to global leaderboards (Wins, Words, Points).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local LeaderboardService = require(ReplicatedStorage.Shared.Services.LeaderboardService.LeaderboardServiceClient)

local function useLeaderboards()
	local wins, setWins = React.useState(LeaderboardService.WinsLeaderboard)
	local words, setWords = React.useState(LeaderboardService.WordsLeaderboard)
	local points, setPoints = React.useState(LeaderboardService.PointsLeaderboard)

	React.useEffect(function()
		local conn = LeaderboardService.OnLeaderboardsUpdated:Connect(function(newWins, newWords, newPoints)
			setWins(newWins)
			setWords(newWords)
			setPoints(newPoints)
		end)

		-- Initial sync
		setWins(LeaderboardService.WinsLeaderboard)
		setWords(LeaderboardService.WordsLeaderboard)
		setPoints(LeaderboardService.PointsLeaderboard)

		return function()
			conn:Disconnect()
		end
	end, {})

	return {
		Wins = wins,
		Words = words,
		Points = points,
	}
end

return useLeaderboards
