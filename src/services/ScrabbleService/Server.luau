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
local Colors = require(ReplicatedStorage.Shared.Modules.Game.Colors)
local DataService = require(ReplicatedStorage.Packages.DataService).server
local CPUService = require(ReplicatedStorage.Shared.Modules.Game.CPUService)

local BOARD_SIZE = ScrabbleConfig.BOARD_SIZE
local RACK_SIZE = ScrabbleConfig.RACK_SIZE
local LETTER_VALUES = ScrabbleConfig.getLetterValues()
local RESIGN_PENALTY = 50

-- Helper to check if a userId is a CPU (IDs <= -100 are CPUs, to avoid conflicts with Studio test player IDs -1, -2, etc.)
local function isCPU(userId: number): boolean
	return userId <= -100
end

-- Get CPU display name
local function getCPUName(cpuId: number, difficulty: string): string
	return CPUService.getCPUName(cpuId, difficulty)
end

type Lobby = {
	Id: string,
	Name: string,
	HostUserId: number,
	Players: { Player },
	Ready: { [number]: boolean },
	MaxPlayers: number,
	Private: boolean,
	Code: string?,
	TimerSeconds: number?, -- 0 = Infinite
	Game: GameState?,
	Spectators: { Player },
	Settings: {
		StarDoublesPoints: boolean?,
		CpuCount: number?,
		CpuDifficulty: string?,
	}?,
	CPUPlayers: { { Id: number, Difficulty: string } }?, -- Virtual CPU players
}

type GameState = {
	Phase: "lobby" | "inGame" | "ended",
	Board: { { string? } },
	Bag: { string },
	Racks: { [number]: { string } },
	Scores: { [number]: number },
	PlayerTimes: { [number]: number }?, -- UserId -> seconds remaining
	TurnOrder: { number },
	TurnIndex: number,
	Log: { string },
	Winner: number?,
	ConsecutivePasses: number?, -- Track consecutive passes to end game
	LastMove: { -- Info about the last valid move for animations
		UserId: number,
		PlacedTiles: { { r: number, c: number } },
		TotalScore: number,
	}?,
	CanPass: boolean?,
	IsBusy: boolean?,
	IsNewHighscore: boolean?,
	ResignedUserId: number?,
	IsNewHighscore: boolean?,
	ResignedUserId: number?,
	Rewards: { [number]: number }?, -- UserId -> Earned Coins
	EliminatedPlayers: { [number]: boolean }?, -- UserId -> was eliminated (timed out)
	SessionStats: {
		[number]: {
			WordsPlaced: number,
			LongestWord: string,
			BestWord: string,
			BestWordScore: number,
		},
	}?,
}

local ScrabbleServiceServer = {
	Networker = nil,
	Lobbies = {} :: { Lobby },
	LobbyByCode = {} :: { [string]: Lobby },
	PlayerLobby = {} :: { [number]: Lobby },
	PlayerSpectating = {} :: { [number]: Lobby },
	NextLobbyId = 1,
	CurrencyService = nil,
	StatsService = nil,
	InventoryService = nil,
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

-- Get player's equipped cosmetic colors for tiles
local function getPlayerEquippedColors(player: Player): { Tile: string, Text: string, Stroke: string }
	if not DataService:hasProfile(player) then
		return Colors.DEFAULT_COLORS
	end
	local equipped = DataService:get(player, { "EquippedColors" })
	if equipped then
		return equipped
	end
	return Colors.DEFAULT_COLORS
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
	local hostName = "Unknown"
	for _, plr in ipairs(lobby.Players) do
		if plr.UserId == lobby.HostUserId then
			hostName = plr.Name
			break
		end
	end

	return {
		Id = lobby.Id,
		Name = lobby.Name,
		HostName = hostName,
		Players = #lobby.Players,
		MaxPlayers = lobby.MaxPlayers,
		Private = lobby.Private,
		Code = if lobby.Private then lobby.Code else nil,
		HostUserId = lobby.HostUserId,
		Phase = lobby.Game and lobby.Game.Phase or "lobby",
	}
end

function ScrabbleServiceServer:init()
	self.Networker = Networker.server.new("ScrabbleService", self, {
		self.CreateLobby,
		self.JoinLobby,
		self.SpectateLobby,
		self.LeaveLobby,
		self.ToggleReady,
		self.StartGame,
		self.PlaceWord,
		self.PassTurn,
		self.ExchangeTiles,
		self.Resign,
		self.ValidateWord,
		self.SendMessage,
		self.TilePreview, -- Handle tile placement previews from players
	})

	task.spawn(function()
		local ServerScriptService = game:GetService("ServerScriptService")
		self.CurrencyService = require(ServerScriptService.Services.CurrencyService.CurrencyServiceServer)
		self.StatsService = require(ServerScriptService.Services.StatsService.StatsServiceServer)
		self.InventoryService = require(ServerScriptService.Services.InventoryService.InventoryServiceServer)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:handleLeave(player)
	end)
	Players.PlayerAdded:Connect(function(player)
		-- Send current lobby list to newcomers
		local summaries = {}
		for _, lobby in ipairs(self.Lobbies) do
			table.insert(summaries, buildLobbySummary(lobby))
		end
		self.Networker:fire(player, "LobbyList", summaries)
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
	local cpuDifficulty = lobby.Settings and lobby.Settings.CpuDifficulty or "Easy"

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
		SpectatorCount = #lobby.Spectators,
		Settings = lobby.Settings,
		CPUPlayers = {}, -- CPU player info for client display
	}

	-- Add human players
	for _, plr in ipairs(lobby.Players) do
		table.insert(state.Players, {
			UserId = plr.UserId,
			Name = plr.Name,
		})
		state.Ready[plr.UserId] = lobby.Ready[plr.UserId] == true
	end

	-- Add CPU players
	if lobby.CPUPlayers then
		for _, cpu in ipairs(lobby.CPUPlayers) do
			table.insert(state.CPUPlayers, {
				UserId = cpu.Id,
				Name = getCPUName(cpu.Id, cpuDifficulty),
				Difficulty = cpu.Difficulty,
			})
			-- CPUs are always ready
			state.Ready[cpu.Id] = true
		end
	end

	local recipients = {}
	for _, p in ipairs(lobby.Players) do
		table.insert(recipients, p)
	end
	for _, p in ipairs(lobby.Spectators) do
		table.insert(recipients, p)
	end

	self.Networker:fire(recipients, "LobbyState", state)
end

function ScrabbleServiceServer:sendGameState(lobby: Lobby)
	if not lobby.Game then
		return
	end
	local game = lobby.Game

	-- Convert board to network-safe format (sparse arrays don't transfer well)
	-- Send as list of {row, col, letter, colors} for occupied cells
	local boardTiles = {}
	for r = 1, BOARD_SIZE do
		for c = 1, BOARD_SIZE do
			local tileData = game.Board[r][c]
			if tileData then
				-- Handle both old (string) and new (table) formats
				if type(tileData) == "table" then
					table.insert(boardTiles, {
						r = r,
						c = c,
						letter = tileData.letter,
						colors = tileData.colors,
						isBlank = tileData.isBlank,
					})
				else
					-- Legacy: just a string letter
					table.insert(boardTiles, {
						r = r,
						c = c,
						letter = tileData,
						colors = Colors.DEFAULT_COLORS,
					})
				end
			end
		end
	end

	-- Build CPU player names mapping for client display
	local cpuPlayerNames = {}
	local cpuDifficulty = game.CPUDifficulty or "Easy"
	if lobby.CPUPlayers then
		for _, cpu in ipairs(lobby.CPUPlayers) do
			-- Use custom name if provided (for player takeovers), otherwise generate from difficulty
			cpuPlayerNames[tostring(cpu.Id)] = cpu.Name or getCPUName(cpu.Id, cpuDifficulty)
		end
	end
	-- Also include any override names (for mid-game player takeovers)
	if game.CPUPlayerNamesOverride then
		for cpuIdStr, name in pairs(game.CPUPlayerNamesOverride) do
			cpuPlayerNames[cpuIdStr] = name
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
		PlayerTimes = game.PlayerTimes,
		FinalPlayers = game.FinalPlayers,
		LastMove = game.LastMove,
		IsBusy = game.IsBusy,
		SessionStats = game.SessionStats,
		Settings = lobby.Settings,
		Rewards = game.Rewards,
		EliminatedPlayers = game.EliminatedPlayers,
		CPUPlayerNames = cpuPlayerNames, -- Map of cpuId -> display name
		-- End game fields (for endingGame phase)
		Penalties = game.Penalties,
		EndingMessage = game.EndingMessage,
		EndingPlayerId = game.EndingPlayerId,
		EndReason = game.EndReason,
	}
	-- Send each player their own rack
	for _, plr in ipairs(lobby.Players) do
		view.Rack = game.Racks[plr.UserId] or {}
		view.IsSpectator = false
		self.Networker:fire({ plr }, "GameState", view)
	end

	-- Send to spectators (empty rack)
	if #lobby.Spectators > 0 then
		view.Rack = {}
		view.IsSpectator = true
		self.Networker:fire(lobby.Spectators, "GameState", view)
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
	local lobby = self.PlayerLobby[player.UserId] or self.PlayerSpectating[player.UserId]
	if not lobby then
		return
	end

	-- Remove from player lookups
	self.PlayerLobby[player.UserId] = nil
	self.PlayerSpectating[player.UserId] = nil

	local isPlayer = false
	-- Remove from players list
	for i = #lobby.Players, 1, -1 do
		if lobby.Players[i] == player then
			table.remove(lobby.Players, i)
			isPlayer = true
		end
	end

	-- Remove from spectators list
	for i = #lobby.Spectators, 1, -1 do
		if lobby.Spectators[i] == player then
			table.remove(lobby.Spectators, i)
		end
	end

	lobby.Ready[player.UserId] = nil
	self.Networker:fire({ player }, "LobbyState", nil)
	self.Networker:fire({ player }, "GameState", nil)

	if isPlayer and lobby.Game and lobby.Game.Phase == "inGame" then
		local game = lobby.Game
		local userId = player.UserId

		-- Convert the player to a CPU instead of removing them
		-- Generate a unique negative CPU ID
		local cpuId = -(1000 + math.abs(userId)) -- Ensures unique negative ID based on original player (uses abs to handle negative Studio IDs)
		local cpuName = player.Name .. " (CPU)"

		-- Find player's position in turn order and replace with CPU
		local wasTheirTurn = false
		for i, turnUserId in ipairs(game.TurnOrder) do
			if turnUserId == userId then
				game.TurnOrder[i] = cpuId
				if game.TurnIndex == i then
					wasTheirTurn = true
				end
				break
			end
		end

		-- Transfer rack to CPU
		if game.Racks[userId] then
			game.Racks[cpuId] = game.Racks[userId]
			game.Racks[userId] = nil
		end

		-- Transfer score to CPU
		if game.Scores[userId] or game.Scores[tostring(userId)] then
			local score = game.Scores[userId] or game.Scores[tostring(userId)] or 0
			game.Scores[cpuId] = score
			game.Scores[tostring(cpuId)] = score
			game.Scores[userId] = nil
			game.Scores[tostring(userId)] = nil
		end

		-- Transfer player time to CPU (if timed game)
		if game.PlayerTimes and (game.PlayerTimes[userId] or game.PlayerTimes[tostring(userId)]) then
			local time = game.PlayerTimes[userId] or game.PlayerTimes[tostring(userId)]
			game.PlayerTimes[cpuId] = time
			game.PlayerTimes[tostring(cpuId)] = time
			game.PlayerTimes[userId] = nil
			game.PlayerTimes[tostring(userId)] = nil
		end

		-- Transfer session stats to CPU
		if game.SessionStats and game.SessionStats[userId] then
			game.SessionStats[cpuId] = game.SessionStats[userId]
			game.SessionStats[userId] = nil
		end

		-- Add to CPUPlayerNames for display
		if not lobby.CPUPlayers then
			lobby.CPUPlayers = {}
		end
		table.insert(lobby.CPUPlayers, { Id = cpuId, Name = cpuName })

		-- Store the CPU name directly in the game for the view builder
		if not game.CPUPlayerNamesOverride then
			game.CPUPlayerNamesOverride = {}
		end
		game.CPUPlayerNamesOverride[tostring(cpuId)] = cpuName

		table.insert(game.Log, player.Name .. " left the game. A CPU has taken over!")

		-- Record last action for turn announcement
		game.LastAction = {
			Type = "cpuTakeover",
			UserId = cpuId,
			Name = cpuName,
		}

		-- Check if all remaining participants are CPUs (no humans left in game)
		local hasHumanPlayer = false
		for _, turnUserId in ipairs(game.TurnOrder) do
			if not isCPU(turnUserId) then
				hasHumanPlayer = true
				break
			end
		end

		if not hasHumanPlayer then
			-- All humans have left - end the game immediately
			game.Phase = "ended"
			table.insert(game.Log, "Game ended - all human players have left.")
			self:sendGameState(lobby)
			self:sendLobbyState(lobby)

			-- Kick all spectators
			for _, spectator in ipairs(lobby.Spectators) do
				self.PlayerSpectating[spectator.UserId] = nil
				self.Networker:fire({ spectator }, "LobbyState", nil)
				self.Networker:fire({ spectator }, "GameState", nil)
				self.Networker:fire({ spectator }, "Error", "All human players have left the game")
			end
			lobby.Spectators = {}

			-- Destroy the lobby
			if lobby.Private and lobby.Code then
				self.LobbyByCode[lobby.Code] = nil
			end
			for i = #self.Lobbies, 1, -1 do
				if self.Lobbies[i] == lobby then
					table.remove(self.Lobbies, i)
				end
			end
			self:broadcastLobbyList()
			return -- Exit early since lobby is destroyed
		end

		self:sendGameState(lobby)
		self:sendLobbyState(lobby)

		-- If it was their turn, trigger CPU to play
		if wasTheirTurn then
			task.defer(function()
				self:triggerCPUTurn(lobby)
			end)
		end
	end
	-- Check if host is leaving during lobby phase (before game starts)
	local hostLeavingInLobby = isPlayer
		and lobby.HostUserId == player.UserId
		and (not lobby.Game or lobby.Game.Phase == "lobby")

	-- Destroy lobby if: no players left, OR host left during lobby phase
	local shouldDestroyLobby = #lobby.Players == 0 or hostLeavingInLobby

	if shouldDestroyLobby then
		-- Kick remaining players if host left during lobby phase
		if hostLeavingInLobby and #lobby.Players > 0 then
			for _, remainingPlayer in ipairs(lobby.Players) do
				self.PlayerLobby[remainingPlayer.UserId] = nil
				self.Networker:fire({ remainingPlayer }, "LobbyState", nil)
				self.Networker:fire({ remainingPlayer }, "GameState", nil)
				self.Networker:fire({ remainingPlayer }, "Error", "Host has left the lobby")
			end
		end

		-- Always kick spectators when destroying lobby
		for _, spectator in ipairs(lobby.Spectators) do
			self.PlayerSpectating[spectator.UserId] = nil
			self.Networker:fire({ spectator }, "LobbyState", nil)
			self.Networker:fire({ spectator }, "GameState", nil)
			if #lobby.Players == 0 then
				self.Networker:fire({ spectator }, "Error", "All players have left the game")
			end
		end

		if lobby.Private and lobby.Code then
			self.LobbyByCode[lobby.Code] = nil
		end
		for i = #self.Lobbies, 1, -1 do
			if self.Lobbies[i] == lobby then
				table.remove(self.Lobbies, i)
			end
		end
	else
		-- Reassign host if needed (only during active game)
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
function ScrabbleServiceServer.CreateLobby(
	self,
	player: Player,
	name: string?,
	maxPlayers: number?,
	isPrivate: boolean?,
	code: string?,
	timerSeconds: number?,
	settings: { StarDoublesPoints: boolean?, CpuCount: number?, CpuDifficulty: string? }?
)
	local cleanName = string.sub(name or "Lobby", 1, 30)
	local cappedMax = math.clamp(maxPlayers or 4, 1, 10) -- Allow solo play (min 1)
	local useCode = if isPrivate then (code and string.upper(string.sub(code, 1, 8)) or self:getOrCreateCode()) else nil

	-- Create CPU players if specified
	local cpuPlayers = {}
	local cpuCount = settings and settings.CpuCount or 0
	local cpuDifficulty = settings and settings.CpuDifficulty or "Easy"

	-- Limit CPUs to 10 - maxPlayers (9 for solo, down to 0 for 10 players)
	local maxCpuAllowed = 10 - cappedMax
	cpuCount = math.clamp(cpuCount, 0, maxCpuAllowed)

	for i = 1, cpuCount do
		table.insert(cpuPlayers, {
			Id = -(100 + i), -- Negative IDs for CPUs (starting at -101 to avoid Studio test player IDs)
			Difficulty = cpuDifficulty,
		})
	end

	local lobby: Lobby = {
		Id = tostring(self.NextLobbyId),
		Name = cleanName,
		HostUserId = player.UserId,
		Players = { player },
		Ready = { [player.UserId] = true },
		MaxPlayers = cappedMax,
		Private = isPrivate == true,
		Code = useCode,
		TimerSeconds = timerSeconds or 0,
		Game = nil,
		Spectators = {},
		Settings = settings,
		CPUPlayers = cpuPlayers,
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
	if lobby and lobby.Private then
		lobby = nil
	end

	if not lobby then
		lobby = self.LobbyByCode[string.upper(idOrCode or "")]
	end

	if not lobby then
		self.Networker:fire({ player }, "Error", "Lobby not found or incorrect code")
		return
	end
	if #lobby.Players >= lobby.MaxPlayers then
		self.Networker:fire({ player }, "Error", "Lobby is full")
		return
	end

	if lobby.Game and lobby.Game.Phase == "inGame" then
		-- Automatically add as spectator
		self:handleSpectate(player, lobby)
		return
	end

	table.insert(lobby.Players, player)
	lobby.Ready[player.UserId] = false
	self.PlayerLobby[player.UserId] = lobby

	self:sendLobbyState(lobby)
	self:broadcastLobbyList()
end

function ScrabbleServiceServer.SpectateLobby(self, player, idOrCode)
	local lobby = self:findLobbyById(idOrCode)
	if not lobby then
		lobby = self.LobbyByCode[string.upper(idOrCode or "")]
	end
	if not lobby then
		self.Networker:fire({ player }, "Error", "Lobby not found")
		return
	end

	self:handleSpectate(player, lobby)
end

function ScrabbleServiceServer:handleSpectate(player, lobby)
	-- Remove from any existing lobby
	self:handleLeave(player)

	-- Add to spectators
	table.insert(lobby.Spectators, player)
	self.PlayerSpectating[player.UserId] = lobby

	-- Send current state
	self:sendLobbyState(lobby)
	if lobby.Game and (lobby.Game.Phase == "inGame" or lobby.Game.Phase == "ended") then
		self:sendGameState(lobby)
	end

	self:broadcastLobbyList()
end

function ScrabbleServiceServer.LeaveLobby(self, player: Player)
	self:handleLeave(player)
end

function ScrabbleServiceServer.ToggleReady(self, player: Player)
	local lobby = self.PlayerLobby[player.UserId]
	if not lobby or lobby.Game then
		return
	end
	lobby.Ready[player.UserId] = not lobby.Ready[player.UserId]
	self:sendLobbyState(lobby)
end

function ScrabbleServiceServer.StartGame(self, player: Player)
	local lobby = self.PlayerLobby[player.UserId]
	if not lobby or lobby.Game then
		return
	end
	if lobby.HostUserId ~= player.UserId then
		self.Networker:fire({ player }, "Error", "Only host can start")
		return
	end
	-- Check minimum participants (human + CPU must be at least 2)
	local cpuCount = lobby.CPUPlayers and #lobby.CPUPlayers or 0
	local totalParticipants = #lobby.Players + cpuCount
	if totalParticipants < 2 then
		self.Networker:fire({ player }, "Error", "Need at least 2 players (including CPUs) to start")
		return
	end

	local bag = ScrabbleConfig.buildBag()
	local racks = {}
	local scores = {}
	local order = {}
	local playerTimes = if lobby.TimerSeconds and lobby.TimerSeconds > 0 then {} else nil

	local sessionStats = {}
	-- Initialize Player Stats
	for _, plr in ipairs(lobby.Players) do
		local rack = {}
		drawTiles(bag, rack, RACK_SIZE)
		racks[plr.UserId] = rack
		scores[plr.UserId] = 0
		sessionStats[plr.UserId] = {
			WordsPlaced = 0,
			LongestWord = "",
			BestWord = "",
			BestWordScore = 0,
		}
		table.insert(order, plr.UserId)
		if playerTimes then
			playerTimes[plr.UserId] = lobby.TimerSeconds
		end
	end

	-- Initialize CPU players
	local cpuDifficulty = lobby.Settings and lobby.Settings.CpuDifficulty or "Easy"
	if lobby.CPUPlayers then
		for _, cpu in ipairs(lobby.CPUPlayers) do
			local rack = {}
			drawTiles(bag, rack, RACK_SIZE)
			racks[cpu.Id] = rack
			scores[cpu.Id] = 0
			sessionStats[cpu.Id] = {
				WordsPlaced = 0,
				LongestWord = "",
				BestWord = "",
				BestWordScore = 0,
			}
			table.insert(order, cpu.Id)
			-- CPUs don't use timers (they play instantly)
		end
	end

	-- SCRABBLE RULES: Determine Turn Order by drawing tiles
	-- Closest to 'A' starts first.
	local drawResults = {}
	for _, userId in ipairs(order) do
		-- Peek at a random tile from the bag (don't remove yet)
		local randomIdx = math.random(#bag)
		local tile = bag[randomIdx]
		drawResults[userId] = tile
	end

	table.sort(order, function(a, b)
		local tileA = drawResults[a]
		local tileB = drawResults[b]

		-- Blanks beat everything (assuming ' ' or '?' for blank)
		local isBlankA = (tileA == " " or tileA == "?")
		local isBlankB = (tileB == " " or tileB == "?")

		if isBlankA and not isBlankB then
			return true
		end
		if isBlankB and not isBlankA then
			return false
		end

		-- Compare letters alphabetically (closer to 'A' wins)
		if tileA ~= tileB then
			return tileA < tileB
		end

		-- Equal letters: deterministic tiebreak by userId (required for sort stability)
		-- Note: Using random() in comparators causes undefined behavior in Lua's sort
		return a < b
	end)

	-- Get first player name (handle CPU)
	local firstPlayerId = order[1]
	local firstPlayerName
	if isCPU(firstPlayerId) then
		firstPlayerName = getCPUName(firstPlayerId, cpuDifficulty)
	else
		local plr = Players:GetPlayerByUserId(firstPlayerId)
		firstPlayerName = plr and plr.Name or "Unknown"
	end
	local logMsg =
		string.format("Turn order decided! %s drew '%s' and goes first.", firstPlayerName, drawResults[order[1]])

	lobby.Game = {
		Phase = "inGame",
		Board = cloneBoard(),
		Bag = bag,
		Racks = racks,
		Scores = scores,
		PlayerTimes = playerTimes,
		TurnOrder = order,
		TurnIndex = 1,
		Log = { logMsg },
		Winner = nil,
		IsBusy = false,
		SessionStats = sessionStats,
		CPUDifficulty = cpuDifficulty, -- Store for CPU turn execution
	}

	-- Start timer loop if enabled (only for human players)
	if playerTimes then
		task.spawn(function()
			while lobby.Game and lobby.Game.Phase == "inGame" do
				task.wait(1)
				if not lobby.Game or not lobby.Game.PlayerTimes then
					break
				end

				local currentTurnUserId = lobby.Game.TurnOrder[lobby.Game.TurnIndex]
				-- Skip timer for CPU players
				if currentTurnUserId and not isCPU(currentTurnUserId) and lobby.Game.PlayerTimes[currentTurnUserId] then
					lobby.Game.PlayerTimes[currentTurnUserId] -= 1

					-- Broadcast timer update to clients
					self:sendGameState(lobby)

					-- Forfeit if time runs out
					if lobby.Game.PlayerTimes[currentTurnUserId] <= 0 then
						lobby.Game.PlayerTimes[currentTurnUserId] = 0
						self:handleForfeit(lobby, currentTurnUserId)
						-- Don't break - handleForfeit may continue the game with remaining players
						-- Loop condition will exit naturally when Phase == "ended"
					end
				end
			end
		end)
	end
	self:sendLobbyState(lobby)
	self:sendGameState(lobby)
	self:broadcastLobbyList()

	-- If first player is CPU, trigger their turn
	if isCPU(order[1]) then
		self:triggerCPUTurn(lobby)
	end
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
local function getWordAt(board: { { string? } }, row: number, col: number, dir: string): (string, number, number)
	local word = ""
	local startRow, startCol = row, col

	if dir == "across" then
		startCol = col
		while startCol > 1 and board[row] and board[row][startCol - 1] do
			startCol = startCol - 1
		end
		local c = startCol
		while c <= BOARD_SIZE and board[row] and board[row][c] do
			word = word .. board[row][c]
			c = c + 1
		end
		startRow = row
	else -- down
		startRow = row
		while startRow > 1 and board[startRow - 1] and board[startRow - 1][col] do
			startRow = startRow - 1
		end
		local r = startRow
		while r <= BOARD_SIZE and board[r] and board[r][col] do
			word = word .. board[r][col]
			r = r + 1
		end
		startCol = col
	end

	return word, startRow, startCol
end

function ScrabbleServiceServer:handleForfeit(lobby: Lobby, forfeitingUserId: number)
	local game = lobby.Game
	if not game or game.Phase == "ended" then
		return
	end

	local forfeiterName = "Unknown"
	for _, p in ipairs(lobby.Players) do
		if p.UserId == forfeitingUserId then
			forfeiterName = p.Name
			break
		end
	end

	-- Find and remove the forfeiting player from turn order
	local playerIndex = nil
	for i, userId in ipairs(game.TurnOrder) do
		if userId == forfeitingUserId then
			playerIndex = i
			break
		end
	end

	if not playerIndex then
		return -- Player not found in turn order
	end

	-- Remove player from turn order
	table.remove(game.TurnOrder, playerIndex)

	-- Track eliminated player (use string key for consistent network serialization)
	if not game.EliminatedPlayers then
		game.EliminatedPlayers = {}
	end
	game.EliminatedPlayers[tostring(forfeitingUserId)] = true

	-- Count remaining players with time (or in turn order)
	local remainingPlayers = #game.TurnOrder

	if remainingPlayers >= 2 then
		-- Game continues with remaining players
		table.insert(game.Log, string.format("%s ran out of time and has been eliminated!", forfeiterName))

		-- Adjust turn index if needed
		if game.TurnIndex > remainingPlayers then
			game.TurnIndex = 1
		elseif game.TurnIndex > playerIndex then
			game.TurnIndex = game.TurnIndex - 1
		end

		-- Update turn to next player
		game.TurnUserId = game.TurnOrder[game.TurnIndex]

		-- Broadcast updated state - timer loop will continue
		self:sendGameState(lobby)
	elseif remainingPlayers == 1 then
		-- Only one player left - they win!
		table.insert(game.Log, string.format("%s ran out of time! Game over.", forfeiterName))
		self:endGame(lobby)
	else
		-- No players left (shouldn't happen normally)
		table.insert(game.Log, string.format("%s ran out of time and has forfeited the game!", forfeiterName))
		self:endGame(lobby)
	end
end

function ScrabbleServiceServer:endGame(lobby: Lobby, endingPlayerId: number?, endReason: string?)
	local game = lobby.Game
	if not game or game.Phase == "ended" or game.Phase == "endingGame" then
		return
	end

	-- Default end reason
	local reason = endReason or "tiles_empty"

	-- Capture final player names/IDs
	game.FinalPlayers = {}
	for _, player in ipairs(lobby.Players) do
		table.insert(game.FinalPlayers, {
			UserId = player.UserId,
			Name = player.Name,
		})
	end
	-- Also add CPU players to FinalPlayers
	local cpuDifficulty = game.CPUDifficulty or "Easy"
	if lobby.CPUPlayers then
		for _, cpu in ipairs(lobby.CPUPlayers) do
			-- Use getCPUName for proper name (cpu.Name may not be set if CPU was added at lobby creation)
			local cpuName = cpu.Name or getCPUName(cpu.Id, cpu.Difficulty or cpuDifficulty)
			table.insert(game.FinalPlayers, {
				UserId = cpu.Id,
				Name = cpuName,
			})
		end
	end

	-- Calculate penalties for remaining tiles (but don't apply yet)
	local letterValues = ScrabbleConfig.getLetterValues()
	local penalties = {}
	for userId, rack in pairs(game.Racks) do
		local penalty = 0
		local tiles = {}
		for _, letter in ipairs(rack) do
			penalty += letterValues[letter] or 1
			table.insert(tiles, letter)
		end
		if penalty > 0 then
			penalties[tostring(userId)] = {
				Amount = penalty,
				Tiles = tiles,
			}
		end
	end

	-- Store penalty data and ending player for client animation
	game.Penalties = penalties
	game.EndingPlayerId = endingPlayerId
	game.EndReason = reason

	-- Generate ending message based on reason
	if reason == "tiles_empty" and endingPlayerId then
		-- Player placed all their tiles
		if isCPU(endingPlayerId) then
			local cpuDifficulty = game.CPUDifficulty or "Easy"
			game.EndingPlayerName = getCPUName(endingPlayerId, cpuDifficulty)
		else
			local player = Players:GetPlayerByUserId(endingPlayerId)
			game.EndingPlayerName = player and player.Name or "A player"
		end
		game.EndingMessage = game.EndingPlayerName:upper() .. " HAS PLACED ALL THEIR TILES!"
	elseif reason == "time_out" then
		game.EndingMessage = "TIME HAS RUN OUT!"
	elseif reason == "all_passed" then
		game.EndingMessage = "ALL PLAYERS HAVE PASSED!"
	else
		game.EndingMessage = "GAME OVER!"
	end

	-- Calculate max penalty to determine animation duration
	local maxPenalty = 0
	for _, p in pairs(penalties) do
		if p.Amount > maxPenalty then
			maxPenalty = p.Amount
		end
	end

	-- Animation timing: 1.5s start delay + 0.15s per point + 2s buffer
	local animationDuration = 1.5 + (maxPenalty * 0.15) + 2.0

	-- Set to endingGame phase for point subtraction animation
	game.Phase = "endingGame"
	self:sendGameState(lobby)
	self:sendLobbyState(lobby)

	-- Wait for client animation, then finalize
	task.delay(animationDuration, function()
		if not lobby.Game or lobby.Game ~= game then
			return -- Lobby was destroyed or game changed
		end
		self:finalizeEndGame(lobby)
	end)
end

function ScrabbleServiceServer:finalizeEndGame(lobby: Lobby)
	local game = lobby.Game
	if not game or game.Phase == "ended" then
		return
	end

	-- Apply penalties now
	for userIdStr, penaltyData in pairs(game.Penalties or {}) do
		local userId = tonumber(userIdStr) or userIdStr
		game.Scores[userId] = (game.Scores[userId] or 0) - penaltyData.Amount
	end

	game.Phase = "ended"

	-- Calculate winner
	local maxScore = -999999
	local winners = {}
	for userId, score in pairs(game.Scores) do
		if score > maxScore then
			maxScore = score
			winners = { userId }
		elseif score == maxScore then
			table.insert(winners, userId)
		end
	end

	if #winners > 0 then
		game.Winner = tonumber(winners[1])

		game.Rewards = {}

		if self.StatsService then
			for _, pInfo in ipairs(game.FinalPlayers) do
				local p = Players:GetPlayerByUserId(pInfo.UserId)
				if p then
					local score = game.Scores[tostring(p.UserId)] or game.Scores[p.UserId] or 0
					local won = (p.UserId == game.Winner)
					self.StatsService:recordGameResult(p, won)

					-- Calculate Rewards
					local reward = math.floor(score / 5) -- 1 coin per 5 points

					if won then
						reward += 50 -- Winner bonus
					end

					-- Participation bonus
					if score > 50 then
						reward += 10
					end

					if reward > 0 then
						game.Rewards[p.UserId] = reward
						if self.CurrencyService then
							self.CurrencyService:addCoins(p, reward, "GameReward")
						end
					end
				end
			end
		end
	end

	self:sendGameState(lobby)
	self:sendLobbyState(lobby)
	self:broadcastLobbyList()
end

function ScrabbleServiceServer:advanceTurn(lobby: Lobby)
	local game = lobby.Game
	if not game then
		return
	end
	game.TurnIndex += 1
	if game.TurnIndex > #game.TurnOrder then
		game.TurnIndex = 1
	end

	-- Check if next player is CPU and trigger their turn
	local nextUserId = game.TurnOrder[game.TurnIndex]
	if nextUserId and isCPU(nextUserId) and game.Phase == "inGame" then
		-- Use task.defer to avoid blocking the current call stack
		task.defer(function()
			self:triggerCPUTurn(lobby)
		end)
	end
end

-- Execute a CPU player's turn
function ScrabbleServiceServer:triggerCPUTurn(lobby: Lobby)
	local game = lobby.Game
	if not game or game.Phase ~= "inGame" then
		return
	end

	local cpuUserId = game.TurnOrder[game.TurnIndex]
	if not cpuUserId or not isCPU(cpuUserId) then
		return
	end

	local difficulty = game.CPUDifficulty or "Easy"
	local cpuName = getCPUName(cpuUserId, difficulty)
	local rack = game.Racks[cpuUserId] or {}

	-- Add artificial delay to feel more natural (0.5 - 2 seconds based on difficulty)
	local delay = if difficulty == "Easy"
		then math.random(15, 25) / 10
		elseif difficulty == "Medium" then math.random(10, 20) / 10
		else math.random(5, 15) / 10
	task.wait(delay)

	-- Check if game is still valid after delay
	if not lobby.Game or lobby.Game.Phase ~= "inGame" then
		return
	end

	-- Find best move using CPUService
	local move = CPUService.findBestMove(game.Board, rack, difficulty, lobby.Settings)

	if move then
		-- Broadcast tile preview to all players before executing
		local previewPositions = {}
		for _, tile in ipairs(move.placedTiles) do
			table.insert(previewPositions, { row = tile.row, col = tile.col })
		end
		self:broadcastCPUTilePreview(lobby, cpuUserId, previewPositions)

		-- Brief delay to show the preview (tiles appearing one by one effect)
		task.wait(0.5)

		-- Clear preview and execute move
		self:broadcastCPUTilePreview(lobby, cpuUserId, {})

		-- Check again if game is still valid
		if not lobby.Game or lobby.Game.Phase ~= "inGame" then
			return
		end

		-- Execute the move
		self:executeCPUMove(lobby, cpuUserId, cpuName, move)
	else
		-- CPU has no valid moves - pass turn
		game.ConsecutivePasses = (game.ConsecutivePasses or 0) + 1
		table.insert(game.Log, cpuName .. " passed (no valid moves).")

		-- Check if everyone has passed
		if game.ConsecutivePasses >= #game.TurnOrder then
			table.insert(game.Log, "All players passed. Game ending.")
			self:endGame(lobby)
		else
			self:advanceTurn(lobby)
			self:finishIfDone(lobby)
			self:sendGameState(lobby)
		end
	end
end

-- Broadcast CPU tile preview to all players and spectators
function ScrabbleServiceServer:broadcastCPUTilePreview(
	lobby: Lobby,
	cpuUserId: number,
	positions: { { row: number, col: number } }
)
	local recipients = {}
	for _, p in ipairs(lobby.Players) do
		table.insert(recipients, p)
	end
	for _, p in ipairs(lobby.Spectators) do
		table.insert(recipients, p)
	end

	if #recipients > 0 then
		self.Networker:fire(recipients, "TilePreview", cpuUserId, positions)
	end
end

-- Execute a CPU's word placement
function ScrabbleServiceServer:executeCPUMove(lobby: Lobby, cpuUserId: number, cpuName: string, move: any)
	local game = lobby.Game
	if not game then
		return
	end

	local rack = game.Racks[cpuUserId] or {}

	-- Remove letters from rack
	for _, tile in ipairs(move.placedTiles) do
		for idx = 1, #rack do
			if rack[idx] == tile.letter then
				table.remove(rack, idx)
				break
			end
		end
	end

	-- Place tiles on board (CPUs use default colors)
	for _, tile in ipairs(move.placedTiles) do
		game.Board[tile.row][tile.col] = {
			letter = tile.letter,
			colors = Colors.DEFAULT_COLORS,
			isBlank = tile.originalLetter == "?",
		}
	end

	-- Update score
	game.Scores[cpuUserId] = (game.Scores[cpuUserId] or 0) + move.score
	table.insert(game.Log, cpuName .. " played " .. move.word .. " for " .. move.score .. " points.")

	-- Refill rack
	drawTiles(game.Bag, rack, RACK_SIZE)
	game.Racks[cpuUserId] = rack

	-- Reset consecutive passes
	game.ConsecutivePasses = 0

	-- Record last move for animations
	local moveTiles = {}
	for _, tile in ipairs(move.placedTiles) do
		table.insert(moveTiles, { r = tile.row, c = tile.col })
	end
	game.LastMove = {
		UserId = cpuUserId,
		PlacedTiles = moveTiles,
		TotalScore = move.score,
	}

	-- Update session stats
	if game.SessionStats and game.SessionStats[cpuUserId] then
		local stats = game.SessionStats[cpuUserId]
		stats.WordsPlaced = (stats.WordsPlaced or 0) + 1
		if #move.word > #(stats.LongestWord or "") then
			stats.LongestWord = move.word
		end
		if move.score > (stats.BestWordScore or 0) then
			stats.BestWordScore = move.score
			stats.BestWord = move.word
		end
	end

	self:advanceTurn(lobby)
	self:finishIfDone(lobby)
	self:sendGameState(lobby)
	self:sendLobbyState(lobby)
end

function ScrabbleServiceServer:finishIfDone(lobby: Lobby, forceEnd: boolean?, endReason: string?)
	local game = lobby.Game
	if not game then
		return
	end

	local endingPlayerId = nil
	if #game.Bag == 0 then
		for userId, rack in pairs(game.Racks) do
			if #rack == 0 then
				endingPlayerId = tonumber(userId) or userId
				break
			end
		end
	end

	if endingPlayerId then
		self:endGame(lobby, endingPlayerId, "tiles_empty")
	elseif forceEnd then
		-- Force end with specified reason (time_out, all_passed, etc.)
		self:endGame(lobby, nil, endReason or "force_end")
	end
end

function ScrabbleServiceServer.PlaceWord(self, player: Player, payload: any)
	local lobby = self.PlayerLobby[player.UserId]
	if not lobby or not lobby.Game or lobby.Game.Phase ~= "inGame" then
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

	if #placedTiles == 0 then
		self.Networker:fire({ player }, "Error", "No tiles to place")
		return
	end

	-- Validate bounds and collect letters needed from rack
	local lettersNeeded = {}
	local blankAssignments = {} -- Track which tiles are blanks with their assigned letters
	for _, tile in ipairs(placedTiles) do
		local r, c = tonumber(tile.row), tonumber(tile.col)
		local letter = string.upper(tile.letter or "")
		local originalLetter = tile.originalLetter -- "?" for blank tiles
		local isBlank = originalLetter == "?"

		if not r or not c or r < 1 or r > BOARD_SIZE or c < 1 or c > BOARD_SIZE then
			self.Networker:fire({ player }, "Error", "Out of bounds")
			return
		end

		-- Check if cell is already occupied
		if game.Board[r] and game.Board[r][c] then
			self.Networker:fire({ player }, "Error", "Cell already occupied")
			return
		end

		-- For blanks, we need "?" in the rack, not the assigned letter
		if isBlank then
			table.insert(lettersNeeded, "?")
			blankAssignments[r .. "," .. c] = letter -- Remember assigned letter
		else
			table.insert(lettersNeeded, letter)
		end
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
				{ r - 1, c },
				{ r + 1, c },
				{ r, c - 1 },
				{ r, c + 1 },
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
			if touchesExisting then
				break
			end
		end

		if not touchesExisting then
			self.Networker:fire({ player }, "Error", "Must connect to existing words")
			return
		end
	end

	-- Create a temporary board with placed tiles to validate words
	-- Note: tempBoard only stores letters (strings) for validation purposes
	local tempBoard = {}
	for r = 1, BOARD_SIZE do
		tempBoard[r] = {}
		for c = 1, BOARD_SIZE do
			local tileData = game.Board[r] and game.Board[r][c]
			if tileData then
				-- Extract just the letter for validation
				tempBoard[r][c] = if type(tileData) == "table" then tileData.letter else tileData
			else
				tempBoard[r][c] = nil
			end
		end
	end

	-- Place tiles on temp board
	for _, tile in ipairs(placedTiles) do
		local r = tonumber(tile.row) or 1
		local c = tonumber(tile.col) or 1
		tempBoard[r][c] = string.upper(tile.letter)
	end

	-- Map of new tile positions for multipliers
	local newTilesMap = {}
	for _, tile in ipairs(placedTiles) do
		newTilesMap[tile.row .. "," .. tile.col] = true
	end

	-- Map of blank tile positions (score as 0)
	local blankTilesMap = {}
	for _, tile in ipairs(placedTiles) do
		if tile.originalLetter == "?" then
			blankTilesMap[tile.row .. "," .. tile.col] = true
		end
	end

	-- Scoring helper
	local function calculateSegmentScore(word, startR, startC, dir)
		local score = 0
		local wordMult = 1
		for i = 1, #word do
			local r, c = startR, startC
			if dir == "across" then
				c = startC + i - 1
			else
				r = startR + i - 1
			end

			local letter = string.sub(word, i, i)
			-- Blank tiles are worth 0 points
			local isBlank = false
			local posKey = r .. "," .. c
			local posKeyStr = tostring(r) .. "," .. tostring(c)

			if blankTilesMap[posKey] or blankTilesMap[posKeyStr] then
				-- Current move blank
				isBlank = true
			elseif game.Board[r] and game.Board[r][c] then
				local cellData = game.Board[r][c]
				if type(cellData) == "table" and cellData.isBlank == true then
					-- Existing board blank
					isBlank = true
				end
			end
			local val = if isBlank then 0 else (LETTER_VALUES[letter] or 0)

			if newTilesMap[r .. "," .. c] then
				local type = ScrabbleConfig.SPECIAL_POSITIONS[r .. "," .. c]

				-- Custom Rule: Star Doubles Points (Checks setting specifically)
				if r == 8 and c == 8 then
					local mult = if lobby.Settings and lobby.Settings.StarDoublesPoints == false then 1 else 2
					wordMult *= mult
					score += val
				elseif type then
					local m = ScrabbleConfig.MULTIPLIERS[type]
					local lMult = m and m.letter or 1
					local wMult = m and m.word or 1

					score += val * lMult
					wordMult *= wMult
				else
					-- Regular cell with no multiplier - still add the base letter value!
					score += val
				end
			else
				score += val
			end
		end
		return score * wordMult
	end

	-- Get the main word
	local firstTile = placedTiles[1]
	local firstRow = tonumber(firstTile.row) or 1
	local firstCol = tonumber(firstTile.col) or 1
	local mainWord, mainStartR, mainStartC = getWordAt(tempBoard, firstRow, firstCol, direction)

	-- Validate main word
	if not isWordValid(mainWord) then
		self.Networker:fire({ player }, "Error", mainWord .. " is not a valid word")
		return
	end

	-- Calculate main word score
	local totalScore = calculateSegmentScore(mainWord, mainStartR, mainStartC, direction)

	-- Check and score all cross-words
	local crossDir = if direction == "across" then "down" else "across"
	for _, tile in ipairs(placedTiles) do
		local r, c = tonumber(tile.row), tonumber(tile.col)
		local crossWord, cwStartR, cwStartC = getWordAt(tempBoard, r, c, crossDir)

		if #crossWord > 1 then
			if not isWordValid(crossWord) then
				self.Networker:fire({ player }, "Error", crossWord .. " is not a valid word")
				return
			end
			-- Add cross-word score
			totalScore += calculateSegmentScore(crossWord, cwStartR, cwStartC, crossDir)
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

	-- Place tiles on actual board (store letter + owner's colors + blank status)
	local playerColors = getPlayerEquippedColors(player)
	for _, tile in ipairs(placedTiles) do
		local r, c = tonumber(tile.row), tonumber(tile.col)
		game.Board[r][c] = {
			letter = string.upper(tile.letter),
			colors = playerColors,
			isBlank = tile.originalLetter == "?",
		}
	end

	-- Update score and log
	game.Scores[userId] = (game.Scores[userId] or 0) + totalScore
	table.insert(game.Log, player.Name .. " played " .. mainWord .. " for " .. totalScore .. " points.")

	-- Refill rack
	drawTiles(game.Bag, rack, RACK_SIZE)
	game.Racks[userId] = rack

	-- Reset consecutive passes on successful move
	game.ConsecutivePasses = 0

	-- Record last move for animations
	local moveTiles = {}
	for _, tile in ipairs(placedTiles) do
		table.insert(moveTiles, { r = tonumber(tile.row), c = tonumber(tile.col) })
	end
	game.LastMove = {
		UserId = userId,
		PlacedTiles = moveTiles,
		TotalScore = totalScore,
	}

	-- Count all words formed (Main Word + Valid Crosswords)
	local wordsCount = 1
	local checkCrossDir = if direction == "across" then "down" else "across"
	for _, tile in ipairs(placedTiles) do
		local r, c = tonumber(tile.row), tonumber(tile.col)
		local crossWord = getWordAt(tempBoard, r, c, checkCrossDir)
		if #crossWord > 1 then
			wordsCount += 1
		end
	end

	-- Update Persistent Stats
	if self.StatsService then
		self.StatsService:incrementStat(player, "TotalPoints", totalScore)
		self.StatsService:incrementStat(player, "TotalWords", wordsCount)
	end

	-- Update Session Stats
	if game.SessionStats and game.SessionStats[userId] then
		local stats = game.SessionStats[userId]
		stats.WordsPlaced += wordsCount

		-- Update longest word
		if #mainWord > #stats.LongestWord then
			stats.LongestWord = mainWord
		end

		-- Also check crosswords just in case one is longer (rare but possible)
		for _, tile in ipairs(placedTiles) do
			local r, c = tonumber(tile.row), tonumber(tile.col)
			local crossWord = getWordAt(tempBoard, r, c, checkCrossDir)
			if #crossWord > #stats.LongestWord then
				stats.LongestWord = crossWord
			end
		end

		-- Update best word (highest single move score)
		if totalScore > stats.BestWordScore then
			stats.BestWordScore = totalScore
			stats.BestWord = mainWord
		end
	end

	self:advanceTurn(lobby)
	self:finishIfDone(lobby)
	self:sendGameState(lobby)
	self:sendLobbyState(lobby)
end

function ScrabbleServiceServer.PassTurn(self, player: Player)
	local lobby = self.PlayerLobby[player.UserId]
	if not lobby or not lobby.Game or lobby.Game.Phase ~= "inGame" then
		return
	end
	if lobby.Game.TurnOrder[lobby.Game.TurnIndex] ~= player.UserId then
		return
	end

	-- Track consecutive passes
	local game = lobby.Game
	game.ConsecutivePasses = (game.ConsecutivePasses or 0) + 1

	table.insert(game.Log, player.Name .. " passed.")

	-- Record last action for turn announcement
	game.LastAction = {
		Type = "pass",
		UserId = player.UserId,
		Name = player.Name,
	}

	-- Check if everyone has passed for 1 full round (everyone skipped consecutively)
	local passesPerRound = #game.TurnOrder

	if game.ConsecutivePasses >= passesPerRound then
		table.insert(game.Log, "All players passed in a row. Ending game.")
		self:finishIfDone(lobby, true)
		self:sendGameState(lobby)
		return
	end

	self:advanceTurn(lobby)
	self:finishIfDone(lobby)
	self:sendGameState(lobby)
end

function ScrabbleServiceServer.ExchangeTiles(
	self,
	player: Player,
	exchangeData: { Letters: { string }, Indices: { number } }
)
	local lobby = self.PlayerLobby[player.UserId]
	if not lobby or not lobby.Game or lobby.Game.Phase ~= "inGame" then
		return
	end

	local game = lobby.Game
	if game.TurnOrder[game.TurnIndex] ~= player.UserId then
		return
	end

	local rack = game.Racks[player.UserId] or {}
	local letters = exchangeData.Letters or {}
	local indices = exchangeData.Indices or {}

	if #letters == 0 then
		self.Networker:fire({ player }, "Error", "No tiles selected for exchange.")
		return
	end

	if #game.Bag < #letters then
		self.Networker:fire({ player }, "Error", "Not enough tiles in bag to exchange " .. #letters .. " tiles.")
		return
	end

	-- Collect letters to return
	local lettersToReturn = {}
	for _, idx in ipairs(indices) do
		if rack[idx] then
			table.insert(lettersToReturn, rack[idx])
		end
	end

	-- Add old letters to bag
	for _, letter in ipairs(lettersToReturn) do
		table.insert(game.Bag, letter)
	end

	-- Shuffle bag
	for i = #game.Bag, 2, -1 do
		local j = math.random(i)
		game.Bag[i], game.Bag[j] = game.Bag[j], game.Bag[i]
	end

	-- Replace in rack with new tiles from the SHUFFLED bag
	for _, idx in ipairs(indices) do
		if rack[idx] and #game.Bag > 0 then
			rack[idx] = table.remove(game.Bag)
		end
	end

	game.Racks[player.UserId] = rack
	table.insert(game.Log, player.Name .. " exchanged " .. #letters .. " tiles.")

	-- Record last action for turn announcement
	game.LastAction = {
		Type = "exchange",
		UserId = player.UserId,
		Name = player.Name,
		Count = #letters,
	}

	-- Reset consecutive passes on exchange (new tiles might allow moves)
	game.ConsecutivePasses = 0

	-- Advance turn and update game state
	self:advanceTurn(lobby)
	self:sendGameState(lobby)
end

function ScrabbleServiceServer.Resign(self, player: Player)
	local lobby = self.PlayerLobby[player.UserId]
	if lobby and lobby.Game and lobby.Game.Phase == "inGame" then
		-- Apply penalty for leaving active game
		if self.CurrencyService then
			local balance = self.CurrencyService:getCoins(player)
			local deduction = math.min(balance, RESIGN_PENALTY)
			if deduction > 0 then
				self.CurrencyService:removeCoins(player, deduction, "resign_penalty")
				self.Networker:fireAll(
					"ChatMessage",
					string.format("System: %s was penalized %d Coins for leaving.", player.Name, deduction)
				)
			end
		end
	end

	self:handleLeave(player)
end

function ScrabbleServiceServer.SendMessage(self, player: Player, message: string)
	-- Validation
	if type(message) ~= "string" or #message == 0 or #message > 200 then
		warn("[Server] Message validation failed")
		return
	end

	local lobby = self.PlayerLobby[player.UserId]
	if not lobby or not lobby.Game then
		warn("[Server] No lobby/game for player")
		return
	end

	-- Filter text
	local TextService = game:GetService("TextService")
	local success, filtered = pcall(function()
		return TextService:FilterStringAsync(message, player.UserId):GetNonChatStringForBroadcastAsync()
	end)

	if not success then
		warn("[ScrabbleServer] Chat filtering failed:", filtered)
		filtered = message -- Fallback for Studio/Testing
	end

	-- Add to log
	table.insert(lobby.Game.Log, {
		UserId = player.UserId,
		Name = player.Name,
		Message = filtered,
	})

	self:sendGameState(lobby)
end

-- Remote function for clients to validate words
function ScrabbleServiceServer.ValidateWord(_self, _player: Player, word: string): boolean
	if type(word) ~= "string" or #word < 2 then
		return false
	end
	return isWordValid(word)
end

-- Handle tile preview positions from players (broadcasts to other players)
function ScrabbleServiceServer.TilePreview(self, player: Player, positions: { { row: number, col: number } })
	local lobby = self.PlayerLobby[player.UserId]
	if not lobby or not lobby.Game or lobby.Game.Phase ~= "inGame" then
		return
	end

	-- Only allow the current turn player to send previews
	local game = lobby.Game
	local currentTurnUserId = game.TurnOrder[game.TurnIndex]
	if currentTurnUserId ~= player.UserId then
		return -- Ignore previews from non-turn players
	end

	-- Validate positions are within bounds
	local validPositions = {}
	for _, pos in ipairs(positions or {}) do
		local r, c = tonumber(pos.row), tonumber(pos.col)
		if r and c and r >= 1 and r <= BOARD_SIZE and c >= 1 and c <= BOARD_SIZE then
			table.insert(validPositions, { row = r, col = c })
		end
	end

	-- Build recipient list (all players and spectators except the sender)
	local recipients = {}
	for _, p in ipairs(lobby.Players) do
		if p.UserId ~= player.UserId then
			table.insert(recipients, p)
		end
	end
	for _, p in ipairs(lobby.Spectators) do
		table.insert(recipients, p)
	end

	-- Broadcast to other players
	if #recipients > 0 then
		self.Networker:fire(recipients, "TilePreview", player.UserId, validPositions)
	end
end

return ScrabbleServiceServer
