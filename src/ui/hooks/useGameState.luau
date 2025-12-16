local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.React)

local ScrabbleServiceClient = require(ReplicatedStorage.Shared.Services.ScrabbleService.ScrabbleServiceClient)

local Player = Players.LocalPlayer

export type ScrabbleState = {
	lobbies: { any },
	lobby: any,
	game: any,
	myUserId: number,
	isMyTurn: boolean,
}

local DEFAULT: ScrabbleState = {
	lobbies = {},
	lobby = nil,
	game = nil,
	myUserId = Player.UserId,
	isMyTurn = false,
}

local ScrabbleContext = React.createContext(nil)

local function ScrabbleProvider(props)
	local state, setState = React.useState(DEFAULT)

	React.useEffect(function()
		local lobbyConn = ScrabbleServiceClient.OnLobbies:Connect(function(list)
			setState(function(prev)
				return {
					lobbies = list or {},
					lobby = prev.lobby,
					game = prev.game,
					myUserId = prev.myUserId,
					isMyTurn = prev.isMyTurn,
				}
			end)
		end)

		local lobbyStateConn = ScrabbleServiceClient.OnLobbyState:Connect(function(lobby)
			setState(function(prev)
				return {
					lobbies = prev.lobbies,
					lobby = lobby,
					game = prev.game,
					myUserId = prev.myUserId,
					isMyTurn = prev.isMyTurn,
				}
			end)
		end)

		local gameConn = ScrabbleServiceClient.OnGameState:Connect(function(game)
			setState(function(prev)
				local turnUserId = game and game.TurnUserId
				return {
					lobbies = prev.lobbies,
					lobby = prev.lobby,
					game = game,
					myUserId = prev.myUserId,
					isMyTurn = turnUserId == prev.myUserId,
				}
			end)
		end)

		local errConn = ScrabbleServiceClient.OnError:Connect(function(message)
			warn("[ScrabbleServiceClient]", message)
		end)

		return function()
			lobbyConn:Disconnect()
			lobbyStateConn:Disconnect()
			gameConn:Disconnect()
			errConn:Disconnect()
		end
	end, {})

	return React.createElement(ScrabbleContext.Provider, {
		value = state,
	}, props.children)
end

local function useScrabbleState(): ScrabbleState
	local context = React.useContext(ScrabbleContext)
	if not context then
		return DEFAULT
	end
	return context
end

return {
	ScrabbleProvider = ScrabbleProvider,
	useScrabbleState = useScrabbleState,
}

