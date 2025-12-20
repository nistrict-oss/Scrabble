local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.React)

local ScrabbleServiceClient = require(ReplicatedStorage.Shared.Services.ScrabbleService.ScrabbleServiceClient)
local SoundUtils = require(ReplicatedStorage.Shared.Modules.Core.SoundUtils)

local Player = Players.LocalPlayer

export type ScrabbleState = {
	lobbies: { any },
	lobby: any,
	game: any,
	myUserId: number,
	isMyTurn: boolean,
	isSpectator: boolean,
}

local DEFAULT: ScrabbleState = {
	lobbies = {},
	lobby = nil,
	game = nil,
	myUserId = Player.UserId,
	isMyTurn = false,
	isSpectator = false,
}

local ScrabbleContext = React.createContext(nil :: ScrabbleState?)

local function ScrabbleProvider(props)
	-- Initialize from current client state (avoids race condition on mount)
	local initialState: ScrabbleState = {
		lobbies = ScrabbleServiceClient.Lobbies or {},
		lobby = ScrabbleServiceClient.CurrentLobby,
		game = ScrabbleServiceClient.CurrentGame,
		myUserId = Player.UserId,
		isMyTurn = false,
		isSpectator = false,
	}

	if initialState.game then
		initialState.isMyTurn = initialState.game.TurnUserId == Player.UserId
		initialState.isSpectator = initialState.game.IsSpectator == true
	end

	local state, setState = React.useState(initialState)

	React.useEffect(function()
		local lobbyConn = ScrabbleServiceClient.OnLobbies:Connect(function(list)
			setState(function(prev)
				return {
					lobbies = list or {},
					lobby = prev.lobby,
					game = prev.game,
					myUserId = prev.myUserId,
					isMyTurn = prev.isMyTurn,
					isSpectator = prev.isSpectator,
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
					isSpectator = prev.isSpectator,
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
					isSpectator = game and game.IsSpectator == true or false,
				}
			end)
		end)

		local errConn = ScrabbleServiceClient.OnError:Connect(function(message)
			warn("[ScrabbleServiceClient]", message)
			SoundUtils.playWrong()
		end)

		return function()
			lobbyConn:Disconnect()
			lobbyStateConn:Disconnect()
			gameConn:Disconnect()
			errConn:Disconnect()
		end
	end, {})

	-- Global Sound Effects Hook
	local prevLogLength = React.useRef(0)
	local prevPhase = React.useRef("lobby" :: any)

	React.useEffect(function()
		local game = state.game
		if not game or not game.Log then
			prevLogLength.current = 0
			prevPhase.current = "lobby"
			return
		end

		local log = game.Log
		local currentLength = #log
		local currentPhase = game.Phase

		-- 1. Log-based sounds (Success/Chat/Wrong)
		if currentLength > prevLogLength.current and prevLogLength.current > 0 then
			-- New entries added
			for i = prevLogLength.current + 1, currentLength do
				local entry = log[i]
				if type(entry) == "string" then
					-- Game Event
					if string.find(entry, "ran out of time!") then
						SoundUtils.playWrong()
					else
						-- Played word, passed, exchanged, resigned
						-- Only play success sound if the game hasn't ended (phase transition handles the big win sound)
						if currentPhase == "inGame" then
							SoundUtils.playCorrect()
						end
					end
				elseif type(entry) == "table" and entry.Message then
					-- Chat Message (only if from someone else)
					if entry.UserId ~= state.myUserId then
						SoundUtils.playChatNotification()
					end
				end
			end
		end

		-- 2. Phase-transition sounds (Victory/Defeat)
		if currentPhase == "ended" and prevPhase.current ~= "ended" then
			if game.Winner then
				if game.Winner == state.myUserId or tostring(game.Winner) == tostring(state.myUserId) then
					SoundUtils.playVictory()
				else
					SoundUtils.playDefeat()
				end
			end
		end

		prevLogLength.current = currentLength
		prevPhase.current = currentPhase
	end, { state.game } :: { any })

	-- Music Management Hook
	React.useEffect(function()
		local phase = if state.game then state.game.Phase else "lobby"

		if phase == "inGame" then
			SoundUtils.stopLobbyMusic()
			SoundUtils.playGameMusic()
		else
			SoundUtils.stopGameMusic()
			SoundUtils.playLobbyMusic()
		end
	end, { if state.game then state.game.Phase else "lobby" } :: { any })

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
	ScrabbleContext = ScrabbleContext,
	ScrabbleProvider = ScrabbleProvider,
	useScrabbleState = useScrabbleState,
}
