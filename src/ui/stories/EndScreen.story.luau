local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages["React-Roblox"])
local EndScreen = require(ReplicatedStorage.UI.screens.GameScreen.EndScreen)

local LocalPlayer = Players.LocalPlayer
local UserId = LocalPlayer and LocalPlayer.UserId or 1001

local mockGameState = {
	Phase = "ended",
	Winner = UserId,
	Scores = {
		[tostring(UserId)] = 342,
		["2002"] = 285,
		["3003"] = 142,
		["4004"] = 89,
	},
	Log = {
		"Final Scoring: -1 point per remaining tile.",
		"PlayerOne won the game!",
	}
}

local mockLobbyState = {
	Players = {
		{ UserId = UserId, Name = LocalPlayer and LocalPlayer.Name or "PlayerOne" },
		{ UserId = 2002, Name = "Steve" },
		{ UserId = 3003, Name = "Alex" },
		{ UserId = 4004, Name = "Bob" },
		{ UserId = 5005, Name = "Charlie" },
		{ UserId = 6006, Name = "Dave" },
		{ UserId = 7007, Name = "Eve" },
		{ UserId = 8008, Name = "Frank" },
	}
}

return function(target)
	local root = ReactRoblox.createRoot(target)
	
	-- Wrap in a full screen frame to simulate screen gui
	root:render(React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(45, 65, 115), -- Match game background
	}, {
		EndScreen = React.createElement(EndScreen, {
			GameState = mockGameState,
			LobbyState = mockLobbyState,
			OnLeave = function() print("Left end screen (mock)") end
		})
	}))

	return function()
		root:unmount()
	end
end
