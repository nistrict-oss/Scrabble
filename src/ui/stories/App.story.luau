local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages["React-Roblox"])
local App = require(ReplicatedStorage.UI.App)

local LeaderboardService = require(ReplicatedStorage.Shared.Services.LeaderboardService.LeaderboardServiceClient)

return function(target)
	-- Mock leaderboard data for story
	local fakeEntry = {
		Rank = 1,
		UserId = 12345678, -- Fake ID
		DisplayName = "hooarcekat",
		Value = 9999,
	}

	LeaderboardService.WinsLeaderboard = { fakeEntry }
	LeaderboardService.WordsLeaderboard = { fakeEntry }
	LeaderboardService.PointsLeaderboard = { fakeEntry }
	LeaderboardService.LeaderboardsUpdated(LeaderboardService, { fakeEntry }, { fakeEntry }, { fakeEntry })

	local root = ReactRoblox.createRoot(target)
	root:render(React.createElement(App))

	return function()
		root:unmount()
	end
end
