local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages["React-Roblox"])
local ServersScreen = require(ReplicatedStorage.UI.screens.HomeScreen.Servers)
local useGameState = require(ReplicatedStorage.UI.hooks.useGameState)

local ScrabbleContext = useGameState.ScrabbleContext

local LocalPlayer = Players.LocalPlayer
local UserId = LocalPlayer and LocalPlayer.UserId or 1001

local mockLobbies = {
	{
		Id = "1",
		Name = "Tournament Central",
		HostName = "Cadyn",
		HostUserId = UserId,
		Players = 2,
		MaxPlayers = 4,
		Private = false,
		Phase = "lobby",
	},
	{
		Id = "2",
		Name = "Pro Game - No Noobs",
		HostName = "ProPlayer",
		HostUserId = 654321,
		Players = 4,
		MaxPlayers = 4,
		Private = true,
		Phase = "lobby",
	},
	{
		Id = "3",
		Name = "Relaxed Play",
		HostName = "ChillVibes",
		HostUserId = 987654,
		Players = 1,
		MaxPlayers = 2,
		Private = false,
		Phase = "inGame",
	}
}

local mockScrabbleState = {
	lobbies = mockLobbies,
	lobby = nil,
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
		Servers = React.createElement(ServersScreen, {})
	}))

	return function()
		root:unmount()
	end
end
