local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages["React-Roblox"])
local GameScreen = require(ReplicatedStorage.UI.screens.GameScreen.Game)

local LocalPlayer = Players.LocalPlayer
local UserId = LocalPlayer and LocalPlayer.UserId or 1001

local mockGameState = {
	Phase = "inGame",
	-- Simple board with one word "HELLO" at center (8,8) to (8,12)
	Board = {
		[8] = {
			[8] = "H",
			[9] = "E", 
			[10] = "L",
			[11] = "L",
			[12] = "O"
		}
	},
	Rack = {"S", "C", "R", "A", "B", "B", "L"},
	Scores = {
		[tostring(UserId)] = 120,
		["2002"] = 85
	},
	TurnOrder = {UserId, 2002},
	TurnIndex = 1,
	TurnUserId = UserId,
	BagCount = 80,
	Log = {
		"Game started!",
		"Player 1 played HELLO for 15 points.",
		{
			UserId = UserId,
			Name = "PlayerOne",
			Message = "Good luck everyone!"
		}
	}
}

local mockLobbyState = {
	Players = {
		{ UserId = UserId, Name = LocalPlayer and LocalPlayer.Name or "PlayerOne" },
		{ UserId = 2002, Name = "PlayerTwo" }
	}
}

return function(target)
	local root = ReactRoblox.createRoot(target)
	
	-- Wrap in a full screen frame to simulate screen gui
	root:render(React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Game = React.createElement(GameScreen, {
			GameState = mockGameState,
			LobbyState = mockLobbyState,
			OnLeave = function() print("Left game (mock)") end
		})
	}))

	return function()
		root:unmount()
	end
end
