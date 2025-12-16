--[[
	ScrabbleServiceClient.luau

	Client-side wrapper for the Scrabble UI flow. Provides Signals for
	lobby lists, lobby state, and game state updates. This is a light
	layer over Networker events.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)

local _Player = Players.LocalPlayer

local ScrabbleServiceClient = {
	Networker = nil,
	Lobbies = {},
	CurrentLobby = nil, -- Renamed from LobbyState to avoid collision with callback
	CurrentGame = nil, -- Renamed from GameState to avoid collision with callback
	OnLobbies = Signal.new(),
	OnLobbyState = Signal.new(),
	OnGameState = Signal.new(),
	OnError = Signal.new(),
}

type LobbySummary = {
	Id: string,
	Name: string,
	Players: number,
	MaxPlayers: number,
	Private: boolean,
	HostUserId: number,
	Phase: string,
}

function ScrabbleServiceClient:init()
	self.Networker = Networker.client.new("ScrabbleService", self)
end

-- Outbound actions
function ScrabbleServiceClient:createLobby(name: string, maxPlayers: number, isPrivate: boolean, code: string?)
	if self.Networker then
		self.Networker:fire("CreateLobby", name, maxPlayers, isPrivate, code)
	end
end

function ScrabbleServiceClient:joinLobby(idOrCode: string)
	if self.Networker then
		self.Networker:fire("JoinLobby", idOrCode)
	end
end

function ScrabbleServiceClient:leaveLobby()
	if self.Networker then
		self.Networker:fire("LeaveLobby")
	end
end

function ScrabbleServiceClient:toggleReady()
	print("[ScrabbleServiceClient] toggleReady called, Networker:", self.Networker ~= nil)
	if self.Networker then
		self.Networker:fire("ToggleReady")
		print("[ScrabbleServiceClient] ToggleReady fired to server")
	else
		warn("[ScrabbleServiceClient] Networker is nil!")
	end
end

function ScrabbleServiceClient:startGame()
	if self.Networker then
		self.Networker:fire("StartGame")
	end
end

function ScrabbleServiceClient:placeWord(placedTiles: { { row: number, col: number, letter: string } }, direction: string)
	if self.Networker then
		self.Networker:fire("PlaceWord", {
			placedTiles = placedTiles,
			direction = direction,
		})
	end
end

function ScrabbleServiceClient:passTurn()
	if self.Networker then
		self.Networker:fire("PassTurn")
	end
end

function ScrabbleServiceClient:exchangeTiles(letters: { string })
	if self.Networker then
		self.Networker:fire("ExchangeTiles", letters)
	end
end

function ScrabbleServiceClient:resign()
	if self.Networker then
		self.Networker:fire("Resign")
	end
end

-- Validate a word against the server dictionary
function ScrabbleServiceClient:validateWord(word: string): boolean
	if self.Networker then
		local success, result = pcall(function()
			return self.Networker:invoke("ValidateWord", word)
		end)
		if success then
			return result == true
		end
	end
	return false
end

-- Inbound Networker callbacks
function ScrabbleServiceClient.LobbyList(self, lobbies: { LobbySummary })
	self.Lobbies = lobbies or {}
	self.OnLobbies:Fire(self.Lobbies)
end

function ScrabbleServiceClient.LobbyState(self, state: any)
	print("[ScrabbleServiceClient] LobbyState received:", state and state.Id or "nil")
	self.CurrentLobby = state
	self.OnLobbyState:Fire(state)
end

function ScrabbleServiceClient.GameState(self, state: any)
	print("[ScrabbleServiceClient] GameState received, Phase:", state and state.Phase or "nil")
	
	-- Reconstruct board from BoardTiles (network-safe format)
	if state and state.BoardTiles then
		local board = {}
		for r = 1, 15 do
			board[r] = {}
			for c = 1, 15 do
				board[r][c] = nil
			end
		end
		
		for _, tile in ipairs(state.BoardTiles) do
			if tile.r and tile.c and tile.letter then
				board[tile.r][tile.c] = tile.letter
			end
		end
		
		state.Board = board
		print("[ScrabbleServiceClient] Reconstructed board with", #state.BoardTiles, "letters")
	end
	
	self.CurrentGame = state
	self.OnGameState:Fire(state)
end

function ScrabbleServiceClient.Error(self, message: string)
	self.OnError:Fire(message or "Unknown error")
end

return ScrabbleServiceClient

