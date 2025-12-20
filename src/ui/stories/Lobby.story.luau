local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages["React-Roblox"])
local LobbyScreen = require(ReplicatedStorage.UI.screens.GameScreen.Lobby)
local useGameState = require(ReplicatedStorage.UI.hooks.useGameState)

local ScrabbleContext = useGameState.ScrabbleContext

local LocalPlayer = Players.LocalPlayer
local UserId = LocalPlayer and LocalPlayer.UserId or 1001

local mockLobbyState = {
	Id = "1",
	Name = "Awesome Scrabble Game",
	HostUserId = UserId,
	MaxPlayers = 4,
	Private = true,
	Code = "SCRAB",
	Players = {
		{ UserId = UserId, Name = LocalPlayer and LocalPlayer.Name or "PlayerOne" },
		{ UserId = 2002, Name = "PlayerTwo" },
		{ UserId = 3003, Name = "PlayerThree" },
	},
	Ready = {
		[UserId] = true,
		[2002] = false,
		[3003] = true,
	},
	Phase = "lobby",
	SpectatorCount = 0,
}

local mockScrabbleState = {
	lobbies = {},
	lobby = mockLobbyState,
	game = nil,
	myUserId = UserId,
	isMyTurn = false,
	isSpectator = false,
}

return function(target)
	local root = ReactRoblox.createRoot(target)
	
	root:render(React.createElement(ScrabbleContext.Provider, {
		value = mockScrabbleState
	}, {
		Lobby = React.createElement(LobbyScreen, {
			LobbyState = mockLobbyState,
			OnLeave = function() print("Left lobby (mock)") end
		})
	}))

	return function()
		root:unmount()
	end
end
