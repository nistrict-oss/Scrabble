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
	OnTilePreview = Signal.new(), -- Incoming tile previews from other players
	OnSystemMessage = Signal.new(),
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
function ScrabbleServiceClient:createLobby(
	name: string,
	maxPlayers: number,
	isPrivate: boolean,
	code: string?,
	timerSeconds: number?,
	settings: { StarDoublesPoints: boolean? }?
)
	self.Networker:fire("CreateLobby", name, maxPlayers, isPrivate, code, timerSeconds, settings)
end

function ScrabbleServiceClient:joinLobby(idOrCode: string)
	if self.Networker then
		self.Networker:fire("JoinLobby", idOrCode)
	end
end

function ScrabbleServiceClient:spectateLobby(idOrCode: string)
	if self.Networker then
		self.Networker:fire("SpectateLobby", idOrCode)
	end
end

function ScrabbleServiceClient:leaveLobby()
	self.CurrentLobby = nil
	self.CurrentGame = nil
	self.OnLobbyState:Fire(nil)
	self.OnGameState:Fire(nil)

	if self.Networker then
		self.Networker:fire("LeaveLobby")
	end
end

function ScrabbleServiceClient:toggleReady()
	if self.Networker then
		self.Networker:fire("ToggleReady")
	end
end

function ScrabbleServiceClient:startGame()
	if self.Networker then
		self.Networker:fire("StartGame")
	end
end

function ScrabbleServiceClient:placeWord(
	placedTiles: { { row: number, col: number, letter: string } },
	direction: string
)
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

function ScrabbleServiceClient:exchangeTiles(exchangeData: { Letters: { string }, Indices: { number } })
	if self.Networker then
		self.Networker:fire("ExchangeTiles", {
			Letters = exchangeData.Letters,
			Indices = exchangeData.Indices,
		})
	end
end

function ScrabbleServiceClient:resign()
	if self.Networker then
		self.Networker:fire("Resign")
	end
end

function ScrabbleServiceClient:sendMessage(message: string)
	if self.Networker then
		self.Networker:fire("SendMessage", message)
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

-- Send tile preview positions to other players (positions only, no letters)
function ScrabbleServiceClient:sendTilePreview(positions: { { row: number, col: number } })
	if self.Networker then
		self.Networker:fire("TilePreview", positions)
	end
end

-- Inbound Networker callbacks
function ScrabbleServiceClient.LobbyList(self, lobbies: { LobbySummary })
	self.Lobbies = lobbies or {}
	self.OnLobbies:Fire(self.Lobbies)
end

function ScrabbleServiceClient.LobbyState(self, state: any)
	self.CurrentLobby = state
	self.OnLobbyState:Fire(state)
end

function ScrabbleServiceClient.GameState(self, state: any)
	-- Reconstruct board from BoardTiles (network-safe format)
	-- Each tile now includes colors for global cosmetic visibility
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
				-- Store full tile data: letter + owner's colors + blank status
				board[tile.r][tile.c] = {
					letter = tile.letter,
					colors = tile.colors, -- { Tile: string, Text: string, Stroke: string }
					isBlank = tile.isBlank, -- true for blank tiles (worth 0 points)
				}
			end
		end

		state.Board = board
	end

	self.CurrentGame = state
	self.OnGameState:Fire(state)
end

function ScrabbleServiceClient.Error(self, message: string)
	self.OnError:Fire(message or "Unknown error")
end

function ScrabbleServiceClient.ChatMessage(self, message: string)
	self.OnSystemMessage:Fire(message)
end

-- Inbound: Receive tile preview positions from other players
function ScrabbleServiceClient.TilePreview(self, userId: number, positions: { { row: number, col: number } })
	self.OnTilePreview:Fire(userId, positions)
end

return ScrabbleServiceClient
