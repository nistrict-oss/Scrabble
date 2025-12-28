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
	-- Each tile has letter and owner's colors
	Board = {
		[8] = {
			[8] = { letter = "H", colors = { Tile = "ocean", Text = "snow", Stroke = "ocean" } },
			[9] = { letter = "E", colors = { Tile = "ocean", Text = "snow", Stroke = "ocean" } },
			[10] = { letter = "L", colors = { Tile = "ocean", Text = "snow", Stroke = "ocean" } },
			[11] = { letter = "L", colors = { Tile = "ocean", Text = "snow", Stroke = "ocean" } },
			[12] = { letter = "O", colors = { Tile = "ocean", Text = "snow", Stroke = "ocean" } },
		},
	},
	Rack = { "S", "C", "R", "A", "B", "B", "L" },
	Scores = {
		[tostring(UserId)] = 120,
		["2002"] = 85,
	},
	TurnOrder = { UserId, 2002 },
	TurnIndex = 1,
	TurnUserId = UserId,
	BagCount = 80,
	Log = {
		"Game started!",
		"Player 1 played HELLO for 15 points.",
		{
			UserId = UserId,
			Name = "PlayerOne",
			Message = "Good luck everyone!",
		},
	},
}

-- Populate with dummy logs
for i = 1, 40 do
	table.insert(mockGameState.Log, {
		UserId = 1000 + (i % 5),
		Name = "Dummy " .. (i % 5),
		Message = "This is dummy message #" .. i .. " to test scrolling behavior! It's quite long to force wrapping.",
	})
end

local mockLobbyState = {
	Players = {
		{ UserId = UserId, Name = LocalPlayer and LocalPlayer.Name or "PlayerOne" },
		{ UserId = 2002, Name = "PlayerTwo" },
	},
}

-- Populate with dummy players
for i = 1, 15 do
	local pid = 3000 + i
	table.insert(mockLobbyState.Players, {
		UserId = pid,
		Name = "Dummy Player " .. i,
	})
	mockGameState.Scores[tostring(pid)] = math.random(10, 500)
	table.insert(mockGameState.TurnOrder, pid)
end

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
			OnLeave = function()
				print("Left game (mock)")
			end,
		}),
	}))

	return function()
		root:unmount()
	end
end
