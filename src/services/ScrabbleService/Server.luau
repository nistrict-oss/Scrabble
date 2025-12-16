--[[
	ScrabbleServiceServer.luau

	Server-side handler for a UI-only Scrabble experience with lobby
	creation, joining, readying, starting, and very lightweight turn
	handling. This is intentionally simplified to bootstrap the new
	UI flow; scoring/validation can be expanded later.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)
local ScrabbleConfig = require(ReplicatedStorage.Shared.Modules.Game.ScrabbleConfig)

local BOARD_SIZE = ScrabbleConfig.BOARD_SIZE
local RACK_SIZE = ScrabbleConfig.RACK_SIZE
local LETTER_VALUES = ScrabbleConfig.getLetterValues()

type Lobby = {
	Id: string,
	Name: string,
	HostUserId: number,
	Players: { Player },
	Ready: { [number]: boolean },
	MaxPlayers: number,
	Private: boolean,
	Code: string?,
	Game: GameState?,
}

type GameState = {
	Phase: "lobby" | "inGame" | "ended",
	Board: { { string? } },
	Bag: { string },
	Racks: { [number]: { string } },
	Scores: { [number]: number },
	TurnOrder: { number },
	TurnIndex: number,
	Log: { string },
	Winner: number?,
}

local ScrabbleServiceServer = {
	Networker = nil,
	Lobbies = {} :: { Lobby },
	LobbyByCode = {} :: { [string]: Lobby },
	PlayerLobby = {} :: { [number]: Lobby },
	NextLobbyId = 1,
}

-- Helpers
local function cloneBoard(): { { string? } }
	local board = {}
	for r = 1, BOARD_SIZE do
		board[r] = {}
		for c = 1, BOARD_SIZE do
			board[r][c] = nil
		end
	end
	return board
end

local function drawTiles(bag: { string }, rack: { string }, targetSize: number)
	while #rack < targetSize and #bag > 0 do
		local tile = table.remove(bag)
		if tile then
			table.insert(rack, tile)
		end
	end
end

local function buildLobbySummary(lobby: Lobby)
	return {
		Id = lobby.Id,
		Name = lobby.Name,
		Players = #lobby.Players,
		MaxPlayers = lobby.MaxPlayers,
		Private = lobby.Private,
		HostUserId = lobby.HostUserId,
		Phase = lobby.Game and lobby.Game.Phase or "lobby",
	}
end

function ScrabbleServiceServer:init()
	self.Networker = Networker.server.new("ScrabbleService", self, {
		self.CreateLobby,
		self.JoinLobby,
		self.LeaveLobby,
		self.ToggleReady,
		self.StartGame,
		self.PlaceWord,
		self.PassTurn,
		self.ExchangeTiles,
		self.Resign,
		self.ValidateWord,
	})

	Players.PlayerRemoving:Connect(function(player)
		self:handleLeave(player)
	end)
	Players.PlayerAdded:Connect(function(player)
		-- Send current lobby list to newcomers
		self.Networker:fire(player, "LobbyList", {})
		self:broadcastLobbyList()
	end)
end

-- Networking: helper broadcasts
function ScrabbleServiceServer:broadcastLobbyList()
	local summaries = {}
	for _, lobby in ipairs(self.Lobbies) do
		table.insert(summaries, buildLobbySummary(lobby))
	end
	self.Networker:fireAll("LobbyList", summaries)
end

function ScrabbleServiceServer:sendLobbyState(lobby: Lobby)
	local state = {
		Id = lobby.Id,
		Name = lobby.Name,
		HostUserId = lobby.HostUserId,
		MaxPlayers = lobby.MaxPlayers,
		Private = lobby.Private,
		Code = lobby.Private and lobby.Code or nil,
		Players = {},
		Ready = {},
		Phase = lobby.Game and lobby.Game.Phase or "lobby",
	}
	for _, plr in ipairs(lobby.Players) do
		table.insert(state.Players, {
			UserId = plr.UserId,
			Name = plr.Name,
		})
		state.Ready[plr.UserId] = lobby.Ready[plr.UserId] == true
	end
	self.Networker:fire(lobby.Players, "LobbyState", state)
end

function ScrabbleServiceServer:sendGameState(lobby: Lobby)
	if not lobby.Game then return end
	local game = lobby.Game
	
	-- Convert board to network-safe format (sparse arrays don't transfer well)
	-- Send as list of {row, col, letter} for occupied cells
	local boardTiles = {}
	for r = 1, BOARD_SIZE do
		for c = 1, BOARD_SIZE do
			local letter = game.Board[r][c]
			if letter then
				table.insert(boardTiles, { r = r, c = c, letter = letter })
			end
		end
	end
	
	local view = {
		Phase = game.Phase,
		BoardTiles = boardTiles, -- Network-safe format
		Scores = game.Scores,
		TurnOrder = game.TurnOrder,
		TurnIndex = game.TurnIndex,
		TurnUserId = game.TurnOrder[game.TurnIndex],
		BagCount = #game.Bag,
		Log = game.Log,
		Winner = game.Winner,
	}
	-- Send each player their own rack
	for _, plr in ipairs(lobby.Players) do
		view.Rack = game.Racks[plr.UserId] or {}
		self.Networker:fire({ plr }, "GameState", view)
	end
end

-- Lobby helpers
function ScrabbleServiceServer:getOrCreateCode(): string
	local code
	repeat
		code = string.upper(string.format("%04x", math.random(0, 0xFFFF)))
	until self.LobbyByCode[code] == nil
	return code
end

function ScrabbleServiceServer:findLobbyById(id: string): Lobby?
	for _, lobby in ipairs(self.Lobbies) do
		if lobby.Id == id then
			return lobby
		end
	end
	return nil
end

function ScrabbleServiceServer:handleLeave(player: Player)
	local lobby = self.PlayerLobby[player.UserId]
	if not lobby then return end
	self.PlayerLobby[player.UserId] = nil

	-- Remove player
	for i = #lobby.Players, 1, -1 do
		if lobby.Players[i] == player then
			table.remove(lobby.Players, i)
		end
	end
	lobby.Ready[player.UserId] = nil

	if lobby.Game and lobby.Game.Phase == "inGame" then
		-- Simple resign handling
		lobby.Game.Scores[player.UserId] = lobby.Game.Scores[player.UserId] or 0
		table.insert(lobby.Game.Log, player.Name .. " resigned.")
		-- Remove from turn order
		for i = #lobby.Game.TurnOrder, 1, -1 do
			if lobby.Game.TurnOrder[i] == player.UserId then
				table.remove(lobby.Game.TurnOrder, i)
				if lobby.Game.TurnIndex > #lobby.Game.TurnOrder then
					lobby.Game.TurnIndex = 1
				end
			end
		end
		if #lobby.Game.TurnOrder <= 1 then
			lobby.Game.Winner = lobby.Game.TurnOrder[1]
			lobby.Game.Phase = "ended"
		end
	end

	if #lobby.Players == 0 then
		-- Destroy lobby
		if lobby.Private and lobby.Code then
			self.LobbyByCode[lobby.Code] = nil
		end
		for i = #self.Lobbies, 1, -1 do
			if self.Lobbies[i] == lobby then
				table.remove(self.Lobbies, i)
			end
		end
	else
		-- Reassign host if needed
		if lobby.HostUserId == player.UserId then
			lobby.HostUserId = lobby.Players[1].UserId
		end
		self:sendLobbyState(lobby)
		if lobby.Game then
			self:sendGameState(lobby)
		end
	end
	self:broadcastLobbyList()
end

-- API implementations
function ScrabbleServiceServer.CreateLobby(self, player: Player, name: string?, maxPlayers: number?, isPrivate: boolean?, code: string?)
	local cleanName = string.sub(name or "Lobby", 1, 30)
	local cappedMax = math.clamp(maxPlayers or 4, 1, 10) -- Allow solo play (min 1)
	local useCode = if isPrivate then (code and string.upper(string.sub(code, 1, 8)) or self:getOrCreateCode()) else nil

	local lobby: Lobby = {
		Id = tostring(self.NextLobbyId),
		Name = cleanName,
		HostUserId = player.UserId,
		Players = { player },
		Ready = { [player.UserId] = true },
		MaxPlayers = cappedMax,
		Private = isPrivate == true,
		Code = useCode,
		Game = nil,
	}
	self.NextLobbyId += 1
	table.insert(self.Lobbies, lobby)
	if lobby.Private and useCode then
		self.LobbyByCode[useCode] = lobby
	end
	self.PlayerLobby[player.UserId] = lobby

	self:sendLobbyState(lobby)
	self:broadcastLobbyList()
end

function ScrabbleServiceServer.JoinLobby(self, player: Player, idOrCode: string)
	-- Leave existing lobby first
	if self.PlayerLobby[player.UserId] then
		self:handleLeave(player)
	end

	local lobby = self:findLobbyById(idOrCode)
	if not lobby then
		lobby = self.LobbyByCode[string.upper(idOrCode or "")]
	end
	if not lobby then
		self.Networker:fire({ player }, "Error", "Lobby not found")
		return
	end
	if #lobby.Players >= lobby.MaxPlayers then
		self.Networker:fire({ player }, "Error", "Lobby is full")
		return
	end

	table.insert(lobby.Players, player)
	lobby.Ready[player.UserId] = false
	self.PlayerLobby[player.UserId] = lobby

	self:sendLobbyState(lobby)
	self:broadcastLobbyList()
end

function ScrabbleServiceServer.LeaveLobby(self, player: Player)
	self:handleLeave(player)
end

function ScrabbleServiceServer.ToggleReady(self, player: Player)
	local lobby = self.PlayerLobby[player.UserId]
	if not lobby or lobby.Game then return end
	lobby.Ready[player.UserId] = not lobby.Ready[player.UserId]
	self:sendLobbyState(lobby)
end

function ScrabbleServiceServer.StartGame(self, player: Player)
	local lobby = self.PlayerLobby[player.UserId]
	if not lobby or lobby.Game then return end
	if lobby.HostUserId ~= player.UserId then
		self.Networker:fire({ player }, "Error", "Only host can start")
		return
	end
	-- Solo play is allowed, no minimum player check needed
	-- Simple ready check
	for _, plr in ipairs(lobby.Players) do
		if lobby.Ready[plr.UserId] ~= true then
			self.Networker:fire({ player }, "Error", "All players must be ready")
			return
		end
	end

	local bag = ScrabbleConfig.buildBag()
	local racks = {}
	local scores = {}
	local order = {}
	for _, plr in ipairs(lobby.Players) do
		local rack = {}
		drawTiles(bag, rack, RACK_SIZE)
		racks[plr.UserId] = rack
		scores[plr.UserId] = 0
		table.insert(order, plr.UserId)
	end

	lobby.Game = {
		Phase = "inGame",
		Board = cloneBoard(),
		Bag = bag,
		Racks = racks,
		Scores = scores,
		TurnOrder = order,
		TurnIndex = 1,
		Log = { "Game started." },
		Winner = nil,
	}
	self:sendLobbyState(lobby)
	self:sendGameState(lobby)
	self:broadcastLobbyList()
end

local function lettersAvailable(rack: { string }, letters: { string }): boolean
	local counts = {}
	for _, ch in ipairs(rack) do
		counts[ch] = (counts[ch] or 0) + 1
	end
	for _, ch in ipairs(letters) do
		counts[ch] = (counts[ch] or 0) - 1
		if counts[ch] < 0 then
			return false
		end
	end
	return true
end

-- Load dictionary for server-side validation
local ScrabbleDictionary = require(ReplicatedStorage.Shared.Modules.Game.ScrabbleDictionary)
ScrabbleDictionary:init()

local function isWordValid(word: string): boolean
	if #word < 2 then
		return false
	end
	return ScrabbleDictionary:isWord(word)
end

-- Check if board is empty
local function isBoardEmpty(board: { { string? } }): boolean
	for r = 1, BOARD_SIZE do
		if board[r] then
			for c = 1, BOARD_SIZE do
				if board[r][c] then
					return false
				end
			end
		end
	end
	return true
end

-- Get word at position in given direction
local function getWordAt(board: { { string? } }, row: number, col: number, dir: string): string
	local word = ""
	
	if dir == "across" then
		local startCol = col
		while startCol > 1 and board[row] and board[row][startCol - 1] do
			startCol = startCol - 1
		end
		local c = startCol
		while c <= BOARD_SIZE and board[row] and board[row][c] do
			word = word .. board[row][c]
			c = c + 1
		end
	else -- down
		local startRow = row
		while startRow > 1 and board[startRow - 1] and board[startRow - 1][col] do
			startRow = startRow - 1
		end
		local r = startRow
		while r <= BOARD_SIZE and board[r] and board[r][col] do
			word = word .. board[r][col]
			r = r + 1
		end
	end
	
	return word
end

function ScrabbleServiceServer:advanceTurn(lobby: Lobby)
	local game = lobby.Game
	if not game then return end
	game.TurnIndex += 1
	if game.TurnIndex > #game.TurnOrder then
		game.TurnIndex = 1
	end
end

function ScrabbleServiceServer:finishIfDone(lobby: Lobby)
	local game = lobby.Game
	if not game then return end
	-- Simple end: if bag empty and any rack empty
	local anyoneEmpty = false
	for userId, rack in pairs(game.Racks) do
		if #rack == 0 then
			game.Winner = userId
			anyoneEmpty = true
			break
		end
	end
	if anyoneEmpty then
		game.Phase = "ended"
		table.insert(game.Log, "Game ended.")
	end
end

function ScrabbleServiceServer.PlaceWord(self, player: Player, payload: any)
	print("[ScrabbleServer] PlaceWord called by", player.Name)
	
	local lobby = self.PlayerLobby[player.UserId]
	if not lobby or not lobby.Game or lobby.Game.Phase ~= "inGame" then 
		print("[ScrabbleServer] No active game for player")
		return 
	end
	local game = lobby.Game
	local userId = player.UserId
	if game.TurnOrder[game.TurnIndex] ~= userId then
		self.Networker:fire({ player }, "Error", "Not your turn")
		return
	end

	-- Accept placedTiles array: { { row: number, col: number, letter: string } }
	local placedTiles = payload and payload.placedTiles or {}
	local direction = payload and payload.direction or "across"
	
	print("[ScrabbleServer] Placed tiles count:", #placedTiles, "Direction:", direction)
	
	if #placedTiles == 0 then
		self.Networker:fire({ player }, "Error", "No tiles to place")
		return
	end
	
	-- Validate bounds and collect letters needed from rack
	local lettersNeeded = {}
	for _, tile in ipairs(placedTiles) do
		local r, c = tonumber(tile.row), tonumber(tile.col)
		local letter = string.upper(tile.letter or "")
		
		if not r or not c or r < 1 or r > BOARD_SIZE or c < 1 or c > BOARD_SIZE then
			self.Networker:fire({ player }, "Error", "Out of bounds")
			return
		end
		
		-- Check if cell is already occupied
		if game.Board[r] and game.Board[r][c] then
			self.Networker:fire({ player }, "Error", "Cell already occupied")
			return
		end
		
		table.insert(lettersNeeded, letter)
	end
	
	-- Check if player has required letters
	local rack = game.Racks[userId] or {}
	if not lettersAvailable(rack, lettersNeeded) then
		self.Networker:fire({ player }, "Error", "Not enough letters in rack")
		return
	end
	
	-- Check first move touches center
	local boardEmpty = isBoardEmpty(game.Board)
	if boardEmpty then
		local touchesCenter = false
		for _, tile in ipairs(placedTiles) do
			if tonumber(tile.row) == 8 and tonumber(tile.col) == 8 then
				touchesCenter = true
				break
			end
		end
		if not touchesCenter then
			self.Networker:fire({ player }, "Error", "First word must touch the center star")
			return
		end
	else
		-- Check adjacency: must connect to existing tiles
		local touchesExisting = false
		for _, tile in ipairs(placedTiles) do
			local r, c = tonumber(tile.row), tonumber(tile.col)
			local neighbors = {
				{ r - 1, c }, { r + 1, c }, { r, c - 1 }, { r, c + 1 }
			}
			for _, pos in ipairs(neighbors) do
				local nr, nc = pos[1], pos[2]
				if nr >= 1 and nr <= BOARD_SIZE and nc >= 1 and nc <= BOARD_SIZE then
					if game.Board[nr] and game.Board[nr][nc] then
						touchesExisting = true
						break
					end
				end
			end
			if touchesExisting then break end
		end
		
		if not touchesExisting then
			self.Networker:fire({ player }, "Error", "Must connect to existing words")
			return
		end
	end
	
	-- Create a temporary board with placed tiles to validate words
	local tempBoard = {}
	for r = 1, BOARD_SIZE do
		tempBoard[r] = {}
		for c = 1, BOARD_SIZE do
			tempBoard[r][c] = game.Board[r] and game.Board[r][c] or nil
		end
	end
	
	-- Place tiles on temp board
	for _, tile in ipairs(placedTiles) do
		local r = tonumber(tile.row) or 1
		local c = tonumber(tile.col) or 1
		tempBoard[r][c] = string.upper(tile.letter)
	end
	
	-- Get the main word
	local firstTile = placedTiles[1]
	local firstRow = tonumber(firstTile.row) or 1
	local firstCol = tonumber(firstTile.col) or 1
	local mainWord = getWordAt(tempBoard, firstRow, firstCol, direction)
	
	-- Validate main word
	if not isWordValid(mainWord) then
		self.Networker:fire({ player }, "Error", mainWord .. " is not a valid word")
		return
	end
	
	-- Calculate main word score
	local totalScore = 0
	for i = 1, #mainWord do
		local ch = string.sub(mainWord, i, i)
		totalScore = totalScore + (LETTER_VALUES[ch] or 1)
	end
	
	-- Check and score all cross-words
	local crossDir = if direction == "across" then "down" else "across"
	for _, tile in ipairs(placedTiles) do
		local r, c = tonumber(tile.row), tonumber(tile.col)
		local crossWord = getWordAt(tempBoard, r, c, crossDir)
		
		if #crossWord > 1 then
			if not isWordValid(crossWord) then
				self.Networker:fire({ player }, "Error", crossWord .. " is not a valid word")
				return
			end
			-- Add cross-word score
			for i = 1, #crossWord do
				local ch = string.sub(crossWord, i, i)
				totalScore = totalScore + (LETTER_VALUES[ch] or 1)
			end
		end
	end
	
	-- All validation passed! Apply changes to actual game state
	
	-- Remove letters from rack
	for _, letter in ipairs(lettersNeeded) do
		for idx = 1, #rack do
			if rack[idx] == letter then
				table.remove(rack, idx)
				break
			end
		end
	end
	
	-- Place tiles on actual board
	for _, tile in ipairs(placedTiles) do
		local r, c = tonumber(tile.row), tonumber(tile.col)
		game.Board[r][c] = string.upper(tile.letter)
	end
	
	-- Update score and log
	game.Scores[userId] = (game.Scores[userId] or 0) + totalScore
	table.insert(game.Log, player.Name .. " played " .. mainWord .. " for " .. totalScore .. " points.")
	
	-- Refill rack
	drawTiles(game.Bag, rack, RACK_SIZE)
	game.Racks[userId] = rack
	
	print("[ScrabbleServer] Word placed successfully:", mainWord, "for", totalScore, "points")
	
	self:advanceTurn(lobby)
	self:finishIfDone(lobby)
	self:sendGameState(lobby)
	self:sendLobbyState(lobby)
end

function ScrabbleServiceServer.PassTurn(self, player: Player)
	local lobby = self.PlayerLobby[player.UserId]
	if not lobby or not lobby.Game or lobby.Game.Phase ~= "inGame" then return end
	if lobby.Game.TurnOrder[lobby.Game.TurnIndex] ~= player.UserId then
		return
	end
	table.insert(lobby.Game.Log, player.Name .. " passed.")
	self:advanceTurn(lobby)
	self:finishIfDone(lobby)
	self:sendGameState(lobby)
end

function ScrabbleServiceServer.ExchangeTiles(self, player: Player, letters: { string })
	local lobby = self.PlayerLobby[player.UserId]
	if not lobby or not lobby.Game or lobby.Game.Phase ~= "inGame" then return end
	local game = lobby.Game
	if game.TurnOrder[game.TurnIndex] ~= player.UserId then
		return
	end
	local rack = game.Racks[player.UserId] or {}
	if #game.Bag < #letters then
		self.Networker:fire({ player }, "Error", "Not enough tiles in bag")
		return
	end
	-- Remove requested letters
	for _, ch in ipairs(letters) do
		local removed = false
		for idx = 1, #rack do
			if rack[idx] == ch then
				table.remove(rack, idx)
				removed = true
				break
			end
		end
		if not removed then
			self.Networker:fire({ player }, "Error", "Letter " .. ch .. " not in rack")
			return
		end
	end
	-- Put old letters into bag
	for _, ch in ipairs(letters) do
		table.insert(game.Bag, ch)
	end
	-- Shuffle bag lightly
	for i = #game.Bag, 2, -1 do
		local j = math.random(i)
		game.Bag[i], game.Bag[j] = game.Bag[j], game.Bag[i]
	end
	-- Draw replacements
	drawTiles(game.Bag, rack, RACK_SIZE)
	game.Racks[player.UserId] = rack
	table.insert(game.Log, player.Name .. " exchanged tiles.")
	self:advanceTurn(lobby)
	self:sendGameState(lobby)
end

function ScrabbleServiceServer.Resign(self, player: Player)
	self:handleLeave(player)
end

-- Remote function for clients to validate words
function ScrabbleServiceServer.ValidateWord(self, _player: Player, word: string): boolean
	if type(word) ~= "string" or #word < 2 then
		return false
	end
	return isWordValid(word)
end

return ScrabbleServiceServer

