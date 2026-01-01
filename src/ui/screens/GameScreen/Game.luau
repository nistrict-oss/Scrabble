--[[
	Game.luau
	
	Main Scrabble gameplay screen. Contains the board, player rack,
	scoreboard, and game controls.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)
local GameConstants = require(ReplicatedStorage.Shared.Modules.Core.GameConstants)
local GameBoard = require(ReplicatedStorage.UI.components.game.GameBoard)
local PlayerRack = require(ReplicatedStorage.UI.components.game.PlayerRack)
local ScoreBoard = require(ReplicatedStorage.UI.components.game.ScoreBoard)
local GameControls = require(ReplicatedStorage.UI.components.game.GameControls)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)
local ScrabbleServiceClient = require(ReplicatedStorage.Shared.Services.ScrabbleService.ScrabbleServiceClient)
local DragPreview = require(ReplicatedStorage.UI.components.game.DragPreview)
local TurnAnnouncement = require(ReplicatedStorage.UI.components.game.TurnAnnouncement)
local WordValidationDisplay = require(ReplicatedStorage.UI.components.game.WordValidationDisplay)
local ScoreContext = require(ReplicatedStorage.UI.contexts.ScoreContext)
local useWordValidatorHook = require(ReplicatedStorage.UI.hooks.useWordValidator) -- Kept original import logic
local EndScreen = require(ReplicatedStorage.UI.screens.GameScreen.EndScreen)
local EliminationScreen = require(ReplicatedStorage.UI.screens.GameScreen.EliminationScreen)
local EndGameAnnouncement = require(ReplicatedStorage.UI.components.game.EndGameAnnouncement)
local BlankTileModal = require(ReplicatedStorage.UI.components.game.BlankTileModal)
local FirstGameHelper = require(ReplicatedStorage.UI.components.game.FirstGameHelper)
local SoundUtils = require(ReplicatedStorage.Shared.Modules.Core.SoundUtils)
local SettingsServiceClient = require(ReplicatedStorage.Shared.Services.SettingsService.SettingsServiceClient)
local useCosmetics = require(ReplicatedStorage.UI.hooks.useCosmetics)

local e = React.createElement
local useWordValidator = useWordValidatorHook.useWordValidator
local useContext = React.useContext

local LocalPlayer = Players.LocalPlayer

export type GameProps = {
	GameState: any,
	LobbyState: any,
	OnLeave: (() -> ())?,
}

return function(props: GameProps)
	local gameState = props.GameState
	local lobbyState = props.LobbyState
	local spawnParticle = useContext(ScoreContext)
	local localCosmetics = useCosmetics() -- Get local player's cosmetics for preview tiles

	-- Settings state
	local showRecentHighlight, setShowRecentHighlight = React.useState(function()
		return SettingsServiceClient:getSetting("ShowRecentHighlight") == true
	end)

	React.useEffect(function()
		local conn = SettingsServiceClient.OnSettingUpdated:Connect(function(name, val)
			if name == "ShowRecentHighlight" then
				setShowRecentHighlight(val)
			end
		end)
		return function()
			conn:Disconnect()
		end
	end, {})

	-- Manage Music
	React.useEffect(function()
		-- Play Game music when Game mounts
		SoundUtils.playGameMusic()
		return function()
			-- Stop music or switch to Lobby music handled by next screen
		end
	end, {})

	-- Local placement state
	local selectedTileIndex, setSelectedTileIndex = React.useState(nil :: number?)
	local placedTiles, setPlacedTiles =
		React.useState({} :: { { row: number, col: number, letter: string, rackIndex: number } })

	-- Blank tile assignments { ["row,col"] = assignedLetter }
	local blankAssignments, setBlankAssignments = React.useState({} :: { [string]: string })
	-- Pending blank tile that needs letter assignment
	local pendingBlankPosition, setPendingBlankPosition =
		React.useState(nil :: { row: number, col: number, rackIndex: number }?)

	-- Drag and drop state
	-- Exchange mode state
	local isExchangeMode, setIsExchangeMode = React.useState(false)
	-- Track exchange selection with rack indices instead of display indices
	local exchangeSelection, setExchangeSelection = React.useState({} :: { [number]: boolean })
	-- Track tiles that were on the board but were selected for exchange
	local stashedTiles, setStashedTiles =
		React.useState({} :: { [number]: { row: number, col: number, letter: string, rackIndex: number } })

	local draggingIndex, setDraggingIndex = React.useState(nil :: number?)
	local draggingLetter, setDraggingLetter = React.useState(nil :: string?)
	local dragHoverCell, setDragHoverCell = React.useState(nil :: { row: number, col: number }?)
	local lastHoverPos = React.useRef(nil :: string?)

	-- Spam Block State
	local isBlocked, setIsBlocked = React.useState(false)

	-- Rack visual order (for shuffling)
	local rackOrder, setRackOrder = React.useState({ 1, 2, 3, 4, 5, 6, 7 })

	-- Resignation confirmation (for leaving multiplayer)
	local showResignConfirm, setShowResignConfirm = React.useState(false)

	-- Tutorial Play Button tracking
	local playButtonPos, setPlayButtonPos = React.useState(nil :: Vector2?)

	-- Submit confirmation (for playing a word)
	local showSubmitConfirm, setShowSubmitConfirm = React.useState(false)

	-- Force spectator mode (for eliminated players who chose to spectate)
	local forceSpectatorMode, setForceSpectatorMode = React.useState(false)

	-- Force show end screen (for eliminated players who want to see their stats before leaving)
	local forceShowEndScreen, setForceShowEndScreen = React.useState(false)

	-- First game tutorial helper visibility
	local showTutorialHelper, setShowTutorialHelper = React.useState(function()
		return not SettingsServiceClient:isTutorialCompleted()
	end)

	-- Chat state
	local chatMessage, setChatMessage = React.useState("")
	local chatInputRef = React.useRef(nil :: TextBox?)
	local logScrollRef = React.useRef(nil :: ScrollingFrame?)

	-- Swap state
	local isExchanging, setIsExchanging = React.useState(false)

	-- Visual scoreboard state (decoupled from server)
	local visualScores, setVisualScores = React.useState({} :: { [string]: number })

	-- Remote tile preview state (tiles being placed by other players)
	local remotePreviewCells, setRemotePreviewCells = React.useState({} :: { { row: number, col: number } })

	-- Listen for tile previews from other players
	React.useEffect(function()
		local conn = ScrabbleServiceClient.OnTilePreview:Connect(function(_userId, positions)
			-- Only show if it's not our turn (other player is placing)
			setRemotePreviewCells(positions or {})
		end)
		return function()
			conn:Disconnect()
		end
	end, {})

	-- Clear remote previews when turn changes or game state changes significantly
	React.useEffect(function()
		setRemotePreviewCells({})
	end, { gameState and gameState.TurnIndex })

	-- Score animation state
	local playerGoalPositions = React.useRef({} :: { [number]: Vector2 })
	local tileAbsolutePositions = React.useRef({} :: { [string]: Vector2 })
	local rackTilePositions = React.useRef({} :: { [number]: Vector2 })
	local pendingAnimations = React.useRef({} :: { [number]: { tiles: { { pos: Vector2, amount: number } } } })
	local prevScores = React.useRef({} :: { [string]: number })

	-- Background gradient animation state
	local hue, setHue = React.useBinding(0.6) -- Start at blue spectrum
	local rotation, setRotation = React.useBinding(0)
	React.useEffect(function()
		local connection = RunService.RenderStepped:Connect(function(dt)
			setHue((hue:getValue() + dt * 0.002) % 1) -- Very very slow shift
			setRotation((rotation:getValue() + dt * 5) % 360) -- Slow rotation
		end)
		return function()
			connection:Disconnect()
		end
	end, {})

	-- Handle Enter key via UserInputService
	React.useEffect(function()
		local conn = UserInputService.InputBegan:Connect(function(input)
			if input.KeyCode == Enum.KeyCode.Return then
				local focused = UserInputService:GetFocusedTextBox()
				if focused and focused == chatInputRef.current then
					local text = focused.Text
					if #text > 0 then
						ScrabbleServiceClient:sendMessage(text)
						setChatMessage("")
						focused.Text = ""
						-- Re-capture focus to keep typing
						task.defer(function()
							focused:CaptureFocus()
						end)
					end
				end
			end
		end)
		return function()
			conn:Disconnect()
		end
	end, {})

	-- Auto-scroll log on new messages
	React.useEffect(function()
		local frame = logScrollRef.current
		if frame and gameState and gameState.Log then
			-- Small delay to ensure AutomaticCanvasSize has updated
			task.delay(0.05, function()
				if frame then
					frame.CanvasPosition = Vector2.new(0, frame.AbsoluteCanvasSize.Y)
				end
			end)
		end
	end, { gameState and gameState.Log and #gameState.Log })

	-- Game data
	local board = if gameState then (gameState.Board or {}) else {}
	local myRack = if gameState then (gameState.Rack or {}) else {} -- Server sends Rack directly per player
	local scores = if gameState then (gameState.Scores or {}) else {}
	local turnOrder = if gameState then (gameState.TurnOrder or {}) else {}
	local turnIndex = if gameState then (gameState.TurnIndex or 1) else 1
	local isSpectator = (gameState and gameState.IsSpectator == true) or forceSpectatorMode
	local tilesInBag = if gameState then (gameState.BagCount or 0) else 0
	local currentTurnUserId = if gameState then (gameState.TurnUserId or turnOrder[turnIndex]) else nil

	-- Slot versioning to trigger animations ONLY on actual changes
	local rackVersions, setRackVersions = React.useState({ 0, 0, 0, 0, 0, 0, 0 })
	local lastRack = React.useRef(myRack)
	React.useEffect(function()
		if myRack then
			setRackVersions(function(prev)
				local next = table.clone(prev)
				local changed = false
				for i = 1, 7 do
					if (myRack[i] or "") ~= (lastRack.current[i] or "") then
						next[i] += 1
						changed = true
					end
				end
				lastRack.current = myRack
				return if changed then next else prev
			end)
		end
	end, { myRack })

	-- Delayed turn switch for animations
	local visualTurnUserId, setVisualTurnUserId = React.useState(currentTurnUserId)
	local lastActualTurnUserId = React.useRef(currentTurnUserId)

	React.useEffect(function()
		if currentTurnUserId ~= lastActualTurnUserId.current then
			-- Turn changed - clear any placed tiles if we had some
			-- This ensures tiles don't persist if our turn was skipped/ended
			local prevWasMyTurn = lastActualTurnUserId.current == LocalPlayer.UserId
			if prevWasMyTurn then
				setPlacedTiles({})
				setBlankAssignments({})
				setSelectedTileIndex(nil)
			end

			lastActualTurnUserId.current = currentTurnUserId

			-- Delay visual turn switch if it was a placement (approx 1.5s for wave)
			-- Otherwise (skip/pass/lobby join) keep it snappy but still consistent
			task.delay(1.5, function()
				setVisualTurnUserId(currentTurnUserId)
			end)
		elseif visualTurnUserId == nil and currentTurnUserId ~= nil then
			-- Initial set
			setVisualTurnUserId(currentTurnUserId)
		end
	end, { currentTurnUserId })

	local isMyTurn = visualTurnUserId == LocalPlayer.UserId and not (gameState and gameState.IsSpectator)

	-- Track which tiles are placed or dragging
	local hiddenIndices = {}
	for _, placed in ipairs(placedTiles) do
		hiddenIndices[placed.rackIndex] = true
	end
	if draggingIndex then
		hiddenIndices[draggingIndex] = true
	end

	-- Build display rack using the current rackOrder (with stable IDs for animation)
	local fullRack = {}
	for _, originalIndex in ipairs(rackOrder) do
		if originalIndex <= #myRack then
			table.insert(fullRack, { id = originalIndex, letter = myRack[originalIndex] })
		end
	end

	-- Build display board (merge server board with local placements)
	local displayBoard = {}
	for r = 1, 15 do
		displayBoard[r] = {}
		for c = 1, 15 do
			displayBoard[r][c] = board[r] and board[r][c] or nil
		end
	end

	local previewCells = {}
	local localColorIds = localCosmetics.Equipped -- Get the color IDs (not Color3 values)
	for _, placed in ipairs(placedTiles) do
		local posKey = placed.row .. "," .. placed.col
		-- Check if this is a blank tile using our assignments
		local isBlankTile = blankAssignments[posKey] ~= nil
		-- Store as tile data with local player's colors for preview
		displayBoard[placed.row][placed.col] = {
			letter = placed.letter,
			colors = localColorIds, -- Local player's equipped colors for their preview tiles
			isBlank = isBlankTile, -- Mark blank tiles so they show 0 points
		}
		table.insert(previewCells, { row = placed.row, col = placed.col })
	end

	-- Send tile preview positions to other players when our placement changes
	React.useEffect(function()
		-- Only send previews if we're placing tiles in an active game AND it's our turn
		local isOurTurn = currentTurnUserId == LocalPlayer.UserId
		if gameState and gameState.Phase == "inGame" and not isSpectator and isOurTurn then
			local positions = {}
			for _, placed in ipairs(placedTiles) do
				table.insert(positions, { row = placed.row, col = placed.col })
			end
			ScrabbleServiceClient:sendTilePreview(positions)
		end
	end, { placedTiles, isSpectator, currentTurnUserId })

	-- Consolidation of settings
	local effectiveSettings = (lobbyState and lobbyState.Settings) or (gameState and gameState.Settings)

	-- Word validation (MUST be called before any early returns)
	local wordValidation = useWordValidator(placedTiles, board, effectiveSettings, blankAssignments)

	-- Turn Notification logic - use array to allow multiple concurrent announcements
	local lastMoveRef = React.useRef(nil :: string?) -- Track last move fingerprint
	local announcements, setAnnouncements = React.useState({} :: { { Name: string, IsLocal: boolean, Key: string } })

	-- Helper to remove a specific announcement by key
	local function removeAnnouncementByKey(keyToRemove: string)
		setAnnouncements(function(prev)
			local filtered = {}
			for _, ann in ipairs(prev) do
				if ann.Key ~= keyToRemove then
					table.insert(filtered, ann)
				end
			end
			return filtered
		end)
	end

	-- This effect triggers on gameState changes and checks if turn changed
	React.useEffect(function()
		if not gameState or gameState.Phase ~= "inGame" then
			setAnnouncements({})
			return
		end

		local announceTurnUserId = gameState.TurnUserId
		local announceTurnIndex = gameState.TurnIndex
		local lastMove = gameState.LastMove
		local lastAction = gameState.LastAction

		-- Create fingerprint from turn state
		local turnFingerprint = tostring(announceTurnIndex or 0) .. "_" .. tostring(announceTurnUserId or 0)

		-- Add LastMove data if it exists (for word placement)
		if lastMove and lastMove.UserId and lastMove.PlacedTiles then
			local tileCount = #lastMove.PlacedTiles
			local firstTile = lastMove.PlacedTiles[1]
			local tileKey = firstTile and (tostring(firstTile.r) .. "," .. tostring(firstTile.c)) or "0,0"
			turnFingerprint = turnFingerprint
				.. "_"
				.. tostring(lastMove.TotalScore or 0)
				.. "_"
				.. tostring(tileCount)
				.. "_"
				.. tileKey
		end

		-- Add LastAction data if it exists (for pass/exchange)
		if lastAction and lastAction.Type then
			turnFingerprint = turnFingerprint
				.. "_action_"
				.. lastAction.Type
				.. "_"
				.. tostring(lastAction.UserId or 0)
		end

		-- Only show announcement if something changed
		if lastMoveRef.current ~= turnFingerprint and turnIndex and turnIndex > 0 then
			lastMoveRef.current = turnFingerprint

			-- Show whose turn it is
			local name = "Unknown"
			if lobbyState and lobbyState.Players then
				for _, p in ipairs(lobbyState.Players) do
					if p.UserId == currentTurnUserId then
						name = p.Name
						break
					end
				end
			end

			-- Check CPUPlayerNames for CPU players
			if gameState.CPUPlayerNames and gameState.CPUPlayerNames[tostring(currentTurnUserId)] then
				name = gameState.CPUPlayerNames[tostring(currentTurnUserId)]
			end

			local newAnnouncement = {
				Name = name,
				IsLocal = currentTurnUserId == LocalPlayer.UserId,
				Key = turnFingerprint,
			}

			-- Add to announcements array
			setAnnouncements(function(prev)
				local next = table.clone(prev)
				table.insert(next, newAnnouncement)
				return next
			end)

			-- Remove THIS specific announcement after animation duration (by key)
			task.delay(3, function()
				removeAnnouncementByKey(turnFingerprint)
			end)
		end
	end, { gameState })

	if not gameState then
		return e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			Loading = e("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "Loading game...",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold, Enum.FontStyle.Italic),
			}),
		})
	end

	-- Build player scores for ScoreBoard
	-- Helper for score lookup (handles string/number key conversion)
	local function getScore(userId): number
		local uidStr = tostring(userId)
		return visualScores[uidStr] or 0
	end

	local playerTimes = gameState.PlayerTimes or {}
	local function getPlayerTime(userId): number?
		return playerTimes[userId] or playerTimes[tostring(userId)]
	end

	local playerScores = {}
	local eliminatedPlayers = gameState.EliminatedPlayers or {}

	-- Build a set of active player IDs (still in turn order)
	local activePlayerSet = {}
	for _, oderId in ipairs(turnOrder) do
		local userId = tonumber(oderId) or oderId
		activePlayerSet[userId] = true
		activePlayerSet[tostring(userId)] = true
	end

	-- First add active players (in turn order)
	for _, oderId in ipairs(turnOrder) do
		-- userId might be string or number after network transfer
		local userId = tonumber(oderId) or oderId
		local player = Players:GetPlayerByUserId(userId)

		-- Get name: check CPUPlayerNames for CPU players (negative IDs)
		local playerName
		if userId < 0 then
			-- CPU player - get name from CPUPlayerNames
			local cpuNames = gameState.CPUPlayerNames or {}
			playerName = cpuNames[tostring(userId)] or ("CPU " .. tostring(math.abs(userId)))
		else
			-- Human player
			playerName = player and player.Name or ("Player " .. tostring(userId))
		end

		table.insert(playerScores, {
			UserId = userId,
			Name = playerName,
			Score = getScore(userId),
			IsCurrentTurn = userId == visualTurnUserId or tostring(userId) == tostring(visualTurnUserId),
			TimeRemaining = getPlayerTime(userId),
			IsEliminated = false,
		})
	end

	-- Then add eliminated players (greyed out at the bottom)
	if lobbyState and lobbyState.Players then
		for _, lobbyPlayer in ipairs(lobbyState.Players) do
			local userId = lobbyPlayer.UserId
			-- Check if this player is eliminated (not in active set)
			local isActive = activePlayerSet[userId] or activePlayerSet[tostring(userId)]
			local isEliminated = eliminatedPlayers[userId] or eliminatedPlayers[tostring(userId)]

			if not isActive and isEliminated then
				local player = Players:GetPlayerByUserId(userId)
				table.insert(playerScores, {
					UserId = userId,
					Name = player and player.Name or lobbyPlayer.Name or ("Player " .. tostring(userId)),
					Score = getScore(userId),
					IsCurrentTurn = false,
					TimeRemaining = nil, -- Don't show time for eliminated players
					IsEliminated = true,
				})
			end
		end
	end

	-- Spam Prevention (Rate Limiting)
	local spamState = React.useRef({ history = {}, blockedUntil = 0 })
	local checkSpam = React.useCallback(function()
		local now = os.clock()
		local s = spamState.current
		if now < s.blockedUntil then
			return false
		end

		-- Filter history window (1.0s)
		local h = {}
		for _, t in ipairs(s.history) do
			if now - t < 1.0 then
				table.insert(h, t)
			end
		end
		s.history = h

		-- Check limit (max 15 messages in window)
		if #s.history >= 15 then
			s.blockedUntil = now + 2 -- Block for 2s
			s.history = {}
			setIsBlocked(true)
			task.delay(2, function()
				setIsBlocked(false)
			end)
			return false
		end

		table.insert(s.history, now)
		return true
	end, {})

	local onParticleComplete = React.useCallback(function(userId, amount)
		setVisualScores(function(prev)
			local next = table.clone(prev)
			local uidStr = tostring(userId)
			next[uidStr] = (next[uidStr] or 0) + amount
			return next
		end)
	end, {})

	-- Handle Score Increases and trigger animations
	React.useEffect(function()
		if not scores then
			return
		end

		setVisualScores(function(prev)
			local next = table.clone(prev)
			local hasChanges = false

			for userIdStr, currentScore in pairs(scores) do
				local userId = tonumber(userIdStr) or userIdStr
				local prevScoreVal = prevScores.current[tostring(userIdStr)] or 0

				-- Initialize visual score if empty
				if next[tostring(userIdStr)] == nil then
					next[tostring(userIdStr)] = currentScore
					hasChanges = true
				end

				-- Force sync if game is fully ended (to ensure final scores are correct)
				if gameState.Phase == "ended" and next[tostring(userIdStr)] ~= currentScore then
					next[tostring(userIdStr)] = currentScore
					hasChanges = true
				end

				if currentScore > prevScoreVal then
					-- Score increased! Check for particles to spawn
					local animationData = pendingAnimations.current[userId]
					local goalPos = playerGoalPositions.current[userId]

					if animationData and goalPos and spawnParticle then
						local totalTiles = #animationData.tiles
						for i, tileData in ipairs(animationData.tiles) do
							-- Extra +0.3s to let the tile pop in first
							spawnParticle(
								tileData.amount,
								tileData.pos,
								goalPos,
								tileData.delay + 0.3,
								function()
									onParticleComplete(userId, tileData.amount)
								end,
								i, -- Tile index (1-based)
								totalTiles -- Total tiles in word
							)
						end
						-- Clear pending record
						pendingAnimations.current[userId] = nil
					else
						-- Check for remote player animation data from LastMove
						local lastMove = gameState.LastMove
						if lastMove and lastMove.UserId == userId and goalPos and spawnParticle then
							local lastMoveTiles = lastMove.PlacedTiles or {}
							local totalScore = lastMove.TotalScore or 0
							local tileCount = #lastMoveTiles
							if tileCount > 0 then
								local tilesToAnimate = {}
								local scorePerTile = math.floor(totalScore / tileCount)
								local remainder = totalScore % tileCount

								for i, tile in ipairs(lastMoveTiles) do
									local posKey = tile.r .. "," .. tile.c
									local pos = tileAbsolutePositions.current[posKey]
									if pos then
										local amount = scorePerTile
										if i == tileCount then
											amount += remainder
										end

										local dist = math.abs(tile.r - 8) + math.abs(tile.c - 8)
										local delay = dist * 0.25
										table.insert(tilesToAnimate, { pos = pos, amount = amount, delay = delay })
									end
								end

								-- Sort by delay (ascending) for pitch
								table.sort(tilesToAnimate, function(a, b)
									return a.delay < b.delay
								end)

								local totalTiles = #tilesToAnimate
								for i, tileData in ipairs(tilesToAnimate) do
									spawnParticle(
										tileData.amount,
										tileData.pos,
										goalPos,
										tileData.delay + 0.3,
										function()
											onParticleComplete(userId, tileData.amount)
										end,
										i,
										totalTiles
									)
								end
							else
								-- Fallback sync
								next[tostring(userIdStr)] = currentScore
								hasChanges = true
							end
						else
							-- No animation data available, sync immediately
							next[tostring(userIdStr)] = currentScore
							hasChanges = true
						end
					end
				end
				prevScores.current[tostring(userIdStr)] = currentScore
			end

			return if hasChanges then next else prev
		end)
	end, { scores })

	-- Time Warning Log Entries (visible to all players in the game log)
	-- Each warning tracks the log index when it was added so it appears in correct position
	local timeWarnings, setTimeWarnings = React.useState({} :: { { text: string, color: string } })
	local timeWarningsShown = React.useRef({
		fiveMin = false,
		oneMin = false,
		tenSec = false,
		countdown = 0, -- Last countdown number shown
	})

	React.useEffect(function()
		if not gameState or gameState.Phase ~= "inGame" then
			-- Reset warnings when game ends or changes
			timeWarningsShown.current = {
				fiveMin = false,
				oneMin = false,
				tenSec = false,
				countdown = 0,
			}
			setTimeWarnings({})
			return
		end

		-- Get current turn player's time
		local currentTurnTime = getPlayerTime(visualTurnUserId)
		if not currentTurnTime then
			return
		end

		-- Get current turn player's name
		local turnPlayer = Players:GetPlayerByUserId(visualTurnUserId)
		local turnPlayerName = turnPlayer and turnPlayer.Name or "Player"
		local isLocal = visualTurnUserId == LocalPlayer.UserId

		-- 5 minute warning (300 seconds)
		if currentTurnTime <= 300 and currentTurnTime > 60 and not timeWarningsShown.current.fiveMin then
			timeWarningsShown.current.fiveMin = true
			local msg = if isLocal
				then "⏱ 5 minutes remaining!"
				else "⏱ " .. turnPlayerName .. " has 5 minutes left"
			setTimeWarnings(function(prev)
				local next = table.clone(prev)
				table.insert(next, { text = msg, color = "warning" })
				return next
			end)
		end

		-- 1 minute warning (60 seconds)
		if currentTurnTime <= 60 and currentTurnTime > 10 and not timeWarningsShown.current.oneMin then
			timeWarningsShown.current.oneMin = true
			local msg = if isLocal then "⚠ 1 minute remaining!" else "⚠ " .. turnPlayerName .. " has 1 minute left"
			setTimeWarnings(function(prev)
				local next = table.clone(prev)
				table.insert(next, { text = msg, color = "warning" })
				return next
			end)
		end

		-- 10 second countdown
		if currentTurnTime <= 10 and currentTurnTime > 0 then
			local secondsLeft = math.floor(currentTurnTime)
			if secondsLeft ~= timeWarningsShown.current.countdown and secondsLeft > 0 then
				timeWarningsShown.current.countdown = secondsLeft
				local msg = if isLocal
					then "⚠ " .. secondsLeft .. " seconds!"
					else turnPlayerName .. ": " .. secondsLeft .. "s"
				setTimeWarnings(function(prev)
					local next = table.clone(prev)
					table.insert(next, { text = msg, color = "critical" })
					return next
				end)
			end
		end

		-- Reset warnings when turn changes
	end, { visualTurnUserId, playerTimes } :: { any })

	-- Reset time warnings when turn changes
	local prevTurnUserId = React.useRef(nil :: any)
	React.useEffect(function()
		if prevTurnUserId.current ~= visualTurnUserId then
			timeWarningsShown.current = {
				fiveMin = false,
				oneMin = false,
				tenSec = false,
				countdown = 0,
			}
			setTimeWarnings({})
			prevTurnUserId.current = visualTurnUserId
		end
	end, { visualTurnUserId })

	-- Penalty particle animation for endingGame phase
	local penaltyAnimationTriggered = React.useRef(false)
	React.useEffect(function()
		if gameState and gameState.Phase == "endingGame" and not penaltyAnimationTriggered.current then
			penaltyAnimationTriggered.current = true
			local penalties = gameState.Penalties or {}

			-- Find the maximum penalty to determine how many ticks we need
			local maxPenalty = 0
			local penaltyTrackers = {} -- Track remaining penalty for each player
			for userIdStr, penaltyData in pairs(penalties) do
				local amount = penaltyData.Amount or 0
				if amount > maxPenalty then
					maxPenalty = amount
				end
				penaltyTrackers[userIdStr] = {
					remaining = amount,
					userId = tonumber(userIdStr) or userIdStr,
				}
			end

			-- Tick down all players simultaneously, -1 at a time
			local tickInterval = 0.15 -- Time between each -1 tick (faster = more dramatic)
			local startDelay = 1.5 -- Wait for announcement to finish

			task.delay(startDelay, function()
				-- Process ticks until all penalties are applied
				local tickCount = 0
				while tickCount < maxPenalty do
					tickCount = tickCount + 1

					-- Apply -1 to each player that still has penalty remaining
					for _, tracker in pairs(penaltyTrackers) do
						if tracker.remaining > 0 then
							tracker.remaining = tracker.remaining - 1
							local goalPos = playerGoalPositions.current[tracker.userId]

							-- Update visual score immediately
							onParticleComplete(tracker.userId, -1)

							-- Spawn -1 particle (optional visual)
							if goalPos and spawnParticle then
								spawnParticle(
									-1, -- Single point deduction
									goalPos + Vector2.new(30, -10), -- Start slightly offset
									goalPos,
									0, -- No delay (we handle timing)
									function() end, -- Score already updated above
									tickCount, -- Use tick as index for pitch variation
									maxPenalty -- Total ticks
								)
							end
						end
					end

					-- Wait before next tick
					if tickCount < maxPenalty then
						task.wait(tickInterval)
					end
				end
			end)
		elseif gameState and gameState.Phase ~= "endingGame" then
			-- Reset when phase changes
			penaltyAnimationTriggered.current = false
		end
	end, { gameState and gameState.Phase, gameState and gameState.Penalties })

	-- (Removed old score-based solo announcement - now handled in LastMove effect above)

	-- Handlers
	local function handleTileClick(index: number, _: string)
		if not isExchangeMode then
			-- In normal mode, clicking letters on the rack is disabled (drag only)
			-- This prevents accidental selection/overlap with drag logic
			return
		end

		if selectedTileIndex == index then
			setSelectedTileIndex(nil)
		else
			setSelectedTileIndex(index)
		end
	end

	-- Drag handlers
	local function handleDragStart(index: number, letter: string)
		setDraggingIndex(index)
		setDraggingLetter(letter)
		setSelectedTileIndex(nil)
	end

	local function handleDragEnter(row: number, col: number)
		if not draggingLetter then
			return
		end
		-- Only allow drop on empty cells
		if board[row] and board[row][col] then
			return
		end
		-- Check if already placed here
		for _, placed in ipairs(placedTiles) do
			if placed.row == row and placed.col == col then
				return
			end
		end
		setDragHoverCell({ row = row, col = col })
	end

	local function handleDragLeave(_row: number, _col: number)
		setDragHoverCell(nil)
	end

	local function handleDragFromBoard(row: number, col: number, letter: string)
		-- Find this tile in placedTiles and get its rack index
		local rackIndex = nil
		local newPlaced = {}
		for _, p in ipairs(placedTiles) do
			if p.row == row and p.col == col then
				rackIndex = p.rackIndex
			else
				table.insert(newPlaced, p)
			end
		end

		if rackIndex then
			-- Remove from placed tiles
			setPlacedTiles(newPlaced)
			-- Check if this was a blank tile BEFORE clearing
			local posKey = row .. "," .. col
			local wasBlank = blankAssignments[posKey] ~= nil
			-- Clear any blank assignment for this position
			if wasBlank then
				setBlankAssignments(function(prev)
					local newAssignments = table.clone(prev)
					newAssignments[posKey] = nil
					return newAssignments
				end)
			end
			-- Start dragging this tile (use original rack letter, not the displayed one)
			setDraggingIndex(rackIndex)
			-- If this was a blank, we need to drag the "?" not the assigned letter
			local originalLetter = if wasBlank then "?" else letter
			setDraggingLetter(originalLetter)
		end
	end

	local function handleDrop(row: number, col: number)
		if not draggingLetter or not draggingIndex then
			return
		end

		-- Check if cell is empty
		if board[row] and board[row][col] then
			setDraggingIndex(nil)
			setDraggingLetter(nil)
			setDragHoverCell(nil)
			return
		end

		-- Check if already placed here
		for _, placed in ipairs(placedTiles) do
			if placed.row == row and placed.col == col then
				setDraggingIndex(nil)
				setDraggingLetter(nil)
				setDragHoverCell(nil)
				return
			end
		end

		-- Place the tile
		local newPlaced = {}
		for _, p in ipairs(placedTiles) do
			table.insert(newPlaced, p)
		end
		table.insert(newPlaced, {
			row = row,
			col = col,
			letter = draggingLetter,
			rackIndex = draggingIndex,
		})
		setPlacedTiles(newPlaced)

		-- If this is a blank tile, show the letter picker modal
		if draggingLetter == "?" then
			setPendingBlankPosition({
				row = row,
				col = col,
				rackIndex = draggingIndex,
			})
		end

		-- Clear drag state
		setDraggingIndex(nil)
		setDraggingLetter(nil)
		setDragHoverCell(nil)
	end

	local function cancelDrag()
		setDraggingIndex(nil)
		setDraggingLetter(nil)
		setDragHoverCell(nil)
	end

	-- Global dragging logic (Hit-testing for Touch/Console compatibility)
	React.useEffect(function()
		if not draggingLetter then
			return
		end

		-- Helper to find what's under the cursor/finger
		local function getObjectAtInput()
			local pos = UserInputService:GetMouseLocation()
			local inset = game:GetService("GuiService"):GetGuiInset()

			-- Note: PlayerGui might not be available immediately, but Game is inside it
			local gui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
			if not gui then
				return nil
			end

			local objects = gui:GetGuiObjectsAtPosition(pos.X - inset.X, pos.Y - inset.Y)
			for _, obj in ipairs(objects) do
				-- Check for board tiles
				if obj.Name:find("BoardTile_") then
					local parts = obj.Name:split("_")
					local r, c = tonumber(parts[2]), tonumber(parts[3])
					if r and c then
						return "board", r, c
					end
				end
				-- Check for rack
				if obj.Name == "PlayerRack" then
					return "rack"
				end
			end
			return nil
		end

		local moveConn = UserInputService.InputChanged:Connect(function(input)
			local isMove = input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.Gamepad1

			if isMove then
				local type, r, c = getObjectAtInput()
				if type == "board" then
					local posKey = r .. "," .. c
					if lastHoverPos.current ~= posKey then
						lastHoverPos.current = posKey
						handleDragEnter(r, c)
					end
				else
					if lastHoverPos.current ~= nil then
						lastHoverPos.current = nil
						setDragHoverCell(nil)
					end
				end
			end
		end)

		local endConn = UserInputService.InputEnded:Connect(function(input)
			local isLeftClick = input.UserInputType == Enum.UserInputType.MouseButton1
			local isTouch = input.UserInputType == Enum.UserInputType.Touch
			local isGamepad = input.UserInputType == Enum.UserInputType.Gamepad1
				and input.KeyCode == Enum.KeyCode.ButtonA

			if isLeftClick or isTouch or isGamepad then
				local type, r, c = getObjectAtInput()

				-- Small delay to avoid race conditions with component state
				task.delay(0.05, function()
					if not draggingLetter then
						return
					end

					if type == "board" then
						handleDrop(r, c)
					else
						cancelDrag() -- Dropped back to rack or outside
					end
				end)
			end
		end)

		return function()
			moveConn:Disconnect()
			endConn:Disconnect()
		end
	end, { draggingLetter, draggingIndex })

	-- Enable virtual cursor for console users on mount
	React.useEffect(function()
		-- We can't explicitly "force" virtual cursor from here easily (it's often automated),
		-- but we ensure the input type is registered for GetMouseLocation.
	end, {})

	local function handleCellClick(row: number, col: number)
		if not selectedTileIndex then
			return
		end

		-- Check if cell is already occupied (on server board)
		if board[row] and board[row][col] then
			return
		end

		-- Check if we already placed a tile here
		for i, placed in ipairs(placedTiles) do
			if placed.row == row and placed.col == col then
				-- Remove the placed tile
				local newPlaced = {}
				for j, p in ipairs(placedTiles) do
					if j ~= i then
						table.insert(newPlaced, p)
					end
				end
				setPlacedTiles(newPlaced)
				setSelectedTileIndex(nil)
				SoundUtils.playTilePop() -- Play sound when removing a tile
				return
			end
		end

		-- Play pop sound when tile is successfully placed
		SoundUtils.playTilePop()

		-- Place the tile
		local newPlaced = {}
		for _, p in ipairs(placedTiles) do
			table.insert(newPlaced, p)
		end
		table.insert(newPlaced, {
			row = row,
			col = col,
			letter = myRack[selectedTileIndex],
			rackIndex = selectedTileIndex,
		})
		setPlacedTiles(newPlaced)
		setSelectedTileIndex(nil)
	end

	local function handleClear()
		setPlacedTiles({})
		setSelectedTileIndex(nil)
		setBlankAssignments({}) -- Clear all blank assignments
	end

	local function handleSubmit()
		if not isMyTurn then
			return
		end
		if #placedTiles == 0 then
			return
		end

		-- Check validation before submitting
		if not wordValidation.isValid then
			SoundUtils.playWrong() -- Play error sound on invalid submission
			return
		end

		-- Check for Move Confirmation setting
		if SettingsServiceClient:getSetting("ConfirmMoves") == true and not showSubmitConfirm then
			setShowSubmitConfirm(true)
			return
		end

		-- Record tiles and their scores for animation
		local tilesToAnimate = {}
		for _, placed in ipairs(placedTiles) do
			local amount = wordValidation.tileScores[placed.rackIndex] or 0
			local pos = tileAbsolutePositions.current[placed.row .. "," .. placed.col]
			if pos then
				-- Match board wave calculation: distance from (8,8) * 0.25
				local dist = math.abs(placed.row - 8) + math.abs(placed.col - 8)
				local delay = dist * 0.25
				table.insert(tilesToAnimate, { pos = pos, amount = amount, delay = delay })
			end
		end

		-- Sort tiles by delay (ascending) so pitch matches when sounds play
		table.sort(tilesToAnimate, function(a, b)
			return a.delay < b.delay
		end)

		pendingAnimations.current[LocalPlayer.UserId] = {
			tiles = tilesToAnimate,
		}

		-- Build tiles with blank assignments for server
		local tilesForServer = {}
		for _, placed in ipairs(placedTiles) do
			local posKey = placed.row .. "," .. placed.col
			local assignedLetter = blankAssignments[posKey]
			if assignedLetter then
				-- This is a blank tile with an assigned letter
				table.insert(tilesForServer, {
					row = placed.row,
					col = placed.col,
					letter = assignedLetter, -- The letter it represents
					originalLetter = "?", -- Mark as blank
					rackIndex = placed.rackIndex,
				})
			else
				-- Normal tile
				table.insert(tilesForServer, placed)
			end
		end

		-- Send placed tiles to server
		ScrabbleServiceClient:placeWord(tilesForServer, wordValidation.direction)

		-- Complete tutorial if this was the first move
		if not SettingsServiceClient:isTutorialCompleted() then
			SettingsServiceClient:completeTutorial()
			setShowTutorialHelper(false)
		end

		-- Clear local state
		handleClear()
		setBlankAssignments({})
		setShowSubmitConfirm(false)
		SoundUtils.playButtonClick() -- Play sound on successful submission
	end

	local function handlePass()
		if not isMyTurn then
			return
		end
		ScrabbleServiceClient:passTurn()
		handleClear()
	end

	local function handleExchange()
		if not isMyTurn then
			return
		end
		if isExchangeMode then
			-- Confirm exchange - send selected tiles to server
			local lettersToExchange = {}
			local exchangeIndices = {}

			for rackIndex, selected in pairs(exchangeSelection) do
				if selected and myRack[rackIndex] then
					table.insert(lettersToExchange, myRack[rackIndex])
					table.insert(exchangeIndices, rackIndex)
				end
			end

			if #lettersToExchange > 0 and not isExchanging then
				setIsExchanging(true)
				-- Store which positions are being exchanged to maintain order
				local exchangeData = {
					Letters = lettersToExchange,
					Indices = exchangeIndices,
				}

				ScrabbleServiceClient:exchangeTiles(exchangeData)
				-- Clear board for next turn
				handleClear()
			end

			-- Exit exchange mode
			setIsExchangeMode(false)
			setExchangeSelection({})
			setStashedTiles({})
			setSelectedTileIndex(nil)
			task.delay(0.5, function()
				setIsExchanging(false)
			end)
		else
			-- Enter exchange mode
			setIsExchangeMode(true)
			setExchangeSelection({})
			setStashedTiles({})
			setSelectedTileIndex(nil)
		end
	end

	local function handleCancelExchange()
		-- Restore stashed tiles to the board
		setPlacedTiles(function(prev)
			local newPlaced = table.clone(prev)
			for _, stashed in pairs(stashedTiles) do
				table.insert(newPlaced, stashed)
			end
			return newPlaced
		end)

		setIsExchangeMode(false)
		setExchangeSelection({})
		setStashedTiles({})
		setIsExchangeMode(false)
		setExchangeSelection({})
		setStashedTiles({})
	end

	local function toggleExchangeTile(rackIndex: number)
		setExchangeSelection(function(prev)
			local newSelection = table.clone(prev)
			newSelection[rackIndex] = not newSelection[rackIndex]

			-- Handle stashing/restoring if the tile was/is on the board
			if newSelection[rackIndex] then
				-- Check if it's on the board
				local foundIndex = nil
				for i, p in ipairs(placedTiles) do
					if p.rackIndex == rackIndex then
						foundIndex = i
						break
					end
				end

				if foundIndex then
					-- Stash it and remove from board
					local stashed = placedTiles[foundIndex]
					setStashedTiles(function(prevStash)
						local newStash = table.clone(prevStash)
						newStash[rackIndex] = stashed
						return newStash
					end)

					setPlacedTiles(function(prevPlaced)
						local newPlaced = table.clone(prevPlaced)
						table.remove(newPlaced, foundIndex)
						return newPlaced
					end)
				end
			else
				-- Unselecting: Check if it was stashed
				local stashed = stashedTiles[rackIndex]
				if stashed then
					-- Restore to board
					setPlacedTiles(function(prevPlaced)
						local newPlaced = table.clone(prevPlaced)
						table.insert(newPlaced, stashed)
						return newPlaced
					end)

					setStashedTiles(function(prevStash)
						local newStash = table.clone(prevStash)
						newStash[rackIndex] = nil
						return newStash
					end)
				end
			end

			return newSelection
		end)
	end

	local function handleShuffle()
		local newOrder = table.clone(rackOrder)
		for i = #newOrder, 2, -1 do
			local j = math.random(i)
			newOrder[i], newOrder[j] = newOrder[j], newOrder[i]
		end
		setRackOrder(newOrder)
		setRackOrder(newOrder)
	end

	local function handleResign()
		if gameState and gameState.Phase == "inGame" then
			setShowResignConfirm(true)
		else
			-- Not in a round, just leave
			if props.OnLeave then
				props.OnLeave()
			end
			ScrabbleServiceClient:leaveLobby()
		end
	end

	local function confirmResign()
		setShowResignConfirm(false)
		ScrabbleServiceClient:resign()
		if props.OnLeave then
			props.OnLeave()
		end
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {

		-- Drag preview (floating tile following mouse)
		DragPreviewUI = draggingLetter and e(DragPreview, {
			Letter = draggingLetter,
		}) or nil,

		-- Main game area
		GameArea = e("Frame", {
			Size = UDim2.fromScale(0.98, 0.98),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			ZIndex = 1,
		}, {
			UIListLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0.01, 0),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),

			-- Left panel: Scoreboard
			LeftPanel = e("Frame", {
				Size = UDim2.fromScale(0.18, 1),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, {
				ScoreBoard = e(ScoreBoard, {
					Players = playerScores,
					TilesRemaining = tilesInBag,
					Settings = effectiveSettings,
					LocalUserId = LocalPlayer.UserId,
					OnReportPosition = function(uid, pos)
						playerGoalPositions.current[uid] = pos
						playerGoalPositions.current[tostring(uid)] = pos
					end,
				}),
			}),

			-- Center: Board and controls
			CenterPanel = e("Frame", {
				Size = UDim2.fromScale(0.6, 1),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				-- Board
				BoardContainer = e("Frame", {
					Size = UDim2.fromScale(1, 0.75),
					BackgroundTransparency = 1,
				}, {
					Board = e(GameBoard, {
						Board = displayBoard,
						PreviewCells = previewCells,
						RemotePreviewCells = remotePreviewCells, -- Show other players' tile placements
						IsWordValid = wordValidation.isValid,
						DragHoverCell = dragHoverCell,
						LastMove = gameState.LastMove, -- Pass recent move data
						LocalUserId = LocalPlayer.UserId, -- Pass local user ID for filtering overlays
						ShowRecentHighlight = showRecentHighlight, -- Pass highlight setting
						OnCellClick = handleCellClick,
						OnCellDrop = handleDrop,
						OnCellDragEnter = handleDragEnter,
						OnCellDragLeave = handleDragLeave,
						OnDragFromBoard = handleDragFromBoard,
						OnReportTilePosition = function(r, c, pos)
							tileAbsolutePositions.current[r .. "," .. c] = pos
						end,
					}),
				}),

				-- Word validation display
				ValidationContainer = e("Frame", {
					Size = UDim2.fromScale(0.35, 0.04),
					Position = UDim2.fromScale(0.5, 0.77),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundTransparency = 1,
				}, {
					Validation = e(WordValidationDisplay, {
						Word = wordValidation.word,
						IsValid = wordValidation.isValid,
						Score = wordValidation.score,
						Direction = wordValidation.direction,
						Error = wordValidation.error,
						Multipliers = wordValidation.multipliers,
						InvalidWords = wordValidation.invalidWords,
					}),
				}),

				-- Rack (Hidden for spectators)
				RackContainer = e("Frame", {
					Size = UDim2.fromScale(0.8, 0.1),
					Position = UDim2.fromScale(0.5, 0.84),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundTransparency = 1,
				}, {
					Rack = not isSpectator
							and e(PlayerRack, {
								Letters = fullRack,
								HiddenIndices = hiddenIndices,
								SelectedIndex = selectedTileIndex,
								DraggingIndex = draggingIndex, -- Use the stable ID
								IsDragging = draggingLetter ~= nil,
								IsDisabled = not isMyTurn or isSpectator,
								IsExchangeMode = isExchangeMode,
								ExchangeSelection = exchangeSelection,
								PlacedTiles = placedTiles,
								IsWordValid = wordValidation.isValid,
								OnTileClick = handleTileClick,
								OnDragStart = handleDragStart,
								OnDropToRack = cancelDrag,
								OnExchangeToggle = toggleExchangeTile,
								OnReportPosition = function(index, pos)
									rackTilePositions.current[index] = pos
								end,
								RackVersions = rackVersions,
							})
						or e("Frame", {
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
						}, {
							UIListLayout = e("UIListLayout", {
								FillDirection = Enum.FillDirection.Horizontal,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								VerticalAlignment = Enum.VerticalAlignment.Center,
								Padding = UDim.new(0.05, 0),
							}),

							SpectatingLabel = e("TextLabel", {
								Size = UDim2.fromScale(0.5, 0.8),
								BackgroundTransparency = 1,
								Text = "SPECTATING",
								TextColor3 = Color3.new(1, 1, 1),
								TextScaled = true,
								LayoutOrder = 1,
								FontFace = Font.new(
									"rbxassetid://11702779517",
									Enum.FontWeight.Heavy,
									Enum.FontStyle.Italic
								),
							}, {
								UIStroke = e("UIStroke", {
									Color = Color3.fromRGB(249, 0, 149),
									Thickness = 2,
								}),
							}),

							LeaveButton = e(TextButton, {
								Text = "Leave Game",
								Variant = "secondary",
								Size = UDim2.fromScale(0.25, 0.7),
								LayoutOrder = 2,
								OnClick = function()
									if props.OnLeave then
										props.OnLeave()
									end
									ScrabbleServiceClient:leaveLobby()
								end,
							}),
						}),
				}),

				-- Controls
				ControlsContainer = e("Frame", {
					Size = UDim2.fromScale(0.9, 0.08),
					Position = UDim2.fromScale(0.5, 0.95),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundTransparency = 1,
				}, {
					Controls = not isSpectator and e(GameControls, {
						IsMyTurn = isMyTurn,
						CanSubmit = #placedTiles > 0 and wordValidation.isValid and not isSpectator,
						IsExchangeMode = isExchangeMode,
						ExchangeCount = (function()
							local count = 0
							for _, selected in pairs(exchangeSelection) do
								if selected then
									count += 1
								end
							end
							return count
						end)(),
						OnSubmit = handleSubmit,
						OnPass = handlePass,
						OnExchange = handleExchange,
						OnShuffle = handleShuffle,
						OnResign = handleResign,
						OnCancelExchange = handleCancelExchange,
						OnClear = handleClear,
						CanPass = true,
						IsBusy = isExchanging,
						OnReportPlayButtonPosition = setPlayButtonPos,
					}) or nil,
				}),
			}),

			-- RightPanel: Game log / chat
			RightPanel = e("Frame", {
				Size = UDim2.fromScale(0.18, 1),
				BackgroundColor3 = Color3.new(1, 1, 1), -- White for gradient
				LayoutOrder = 3,
			}, {
				UIGradient = e("UIGradient", {
					Color = ColorSequence.new(GameConstants.Gradients.frame),
					Rotation = 90,
				}),
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0.03, 0),
				}),

				UIStroke = e("UIStroke", {
					Color = Color3.new(1, 1, 1),
					Thickness = 2,
				}),

				-- LOG SECTION (Fill height for spectators)
				LogContainer = e("Frame", {
					Size = if isSpectator then UDim2.fromScale(1, 0.95) else UDim2.fromScale(1, 0.92),
					BackgroundTransparency = 1,
				}, {
					Header = e("TextLabel", {
						Size = UDim2.fromScale(1, 0.08),
						Position = UDim2.fromScale(0, 0.01),
						BackgroundTransparency = 1,
						Text = "GAME LOG",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
						FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
					}, {
						UIPadding = e("UIPadding", {
							PaddingTop = UDim.new(0.2, 0),
							PaddingBottom = UDim.new(0.2, 0),
						}),
					}),

					LogScroll = e(
						"ScrollingFrame",
						{
							ref = logScrollRef,
							Size = UDim2.fromScale(0.9, 0.9),
							Position = UDim2.fromScale(0.5, 0.1),
							AnchorPoint = Vector2.new(0.5, 0),
							BackgroundTransparency = 1,
							ScrollBarThickness = 0,
							AutomaticCanvasSize = Enum.AutomaticSize.Y,
							CanvasSize = UDim2.fromScale(0, 0),
						},
						(function()
							local children = {
								UIListLayout = e("UIListLayout", {
									SortOrder = Enum.SortOrder.LayoutOrder,
									VerticalAlignment = Enum.VerticalAlignment.Bottom,
									Padding = UDim.new(0, 4),
								}),
								UIPadding = e("UIPadding", {
									PaddingLeft = UDim.new(0.02, 0),
									PaddingRight = UDim.new(0.02, 0),
								}),
							}

							-- Log entries
							local rawLog = gameState.Log or {}

							-- Pre-process log to merge consecutive messages
							local processedLog = {}
							local lastMergedEntry = nil

							for _, entry in ipairs(rawLog) do
								if type(entry) == "table" and entry.UserId and entry.Message then
									-- Chat Message
									if lastMergedEntry and lastMergedEntry.UserId == entry.UserId then
										-- Append to existing entry
										lastMergedEntry.Message = lastMergedEntry.Message .. "\n" .. entry.Message
										lastMergedEntry.MessageCount = (lastMergedEntry.MessageCount or 1) + 1
									else
										-- Start new entry block
										local newEntry = table.clone(entry)
										newEntry.MessageCount = 1
										table.insert(processedLog, newEntry)
										lastMergedEntry = newEntry
									end
								else
									-- System Message
									table.insert(processedLog, entry)
									lastMergedEntry = nil
								end
							end

							-- Add time warning entries at the end of the log
							-- (Simpler approach: just append instead of trying to insert at specific positions)
							for _, warning in ipairs(timeWarnings) do
								table.insert(processedLog, {
									isTimeWarning = true,
									text = warning.text,
									color = warning.color,
								})
							end

							local log = processedLog

							for i, entry in ipairs(log) do
								if type(entry) == "table" and entry.isTimeWarning then
									-- TIME WARNING (Colored text)
									local warningColor = if entry.color == "critical"
										then Color3.fromRGB(255, 80, 80) -- Red for critical
										else Color3.fromRGB(255, 200, 80) -- Yellow for warning
									children["Log_" .. i] = e("TextLabel", {
										Size = UDim2.new(1, 0, 0, 18),
										BackgroundTransparency = 1,
										Text = entry.text,
										TextColor3 = warningColor,
										TextScaled = true,
										TextWrapped = true,
										TextXAlignment = Enum.TextXAlignment.Left,
										LayoutOrder = i,
										FontFace = Font.new(
											"rbxassetid://11702779517",
											Enum.FontWeight.Heavy,
											Enum.FontStyle.Normal
										),
									})
								elseif type(entry) == "table" and entry.UserId and entry.Message then
									-- CHAT MESSAGE (PFP + Name + Text)
									children["Log_" .. i] = e("Frame", {
										Size = UDim2.fromScale(1, 0),
										AutomaticSize = Enum.AutomaticSize.Y,
										BackgroundTransparency = 1,
										LayoutOrder = i,
									}, {
										UIPadding = e("UIPadding", {
											PaddingBottom = UDim.new(0, 5), -- 5px px padding between blocks
										}),

										Avatar = e("ImageLabel", {
											Size = UDim2.fromOffset(24, 24), -- Fixed pixel size
											Position = UDim2.new(0, 0, 0, 0),
											BackgroundTransparency = 1,
											Image = "rbxthumb://type=AvatarHeadShot&id="
												.. entry.UserId
												.. "&w=150&h=150",
										}, {
											UICorner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
											UIStroke = e("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }),
										}),

										TextContainer = e("Frame", {
											Size = UDim2.new(1, -30, 0, 0), -- Full width minus avatar
											Position = UDim2.fromOffset(30, 0), -- After avatar
											BackgroundTransparency = 1,
											AutomaticSize = Enum.AutomaticSize.Y,
										}, {
											UIListLayout = e("UIListLayout", {
												FillDirection = Enum.FillDirection.Vertical,
												SortOrder = Enum.SortOrder.LayoutOrder,
											}),

											NameLabel = e("TextLabel", {
												Size = UDim2.new(1, 0, 0, 18), -- Fixed height for name
												BackgroundTransparency = 1,
												Text = entry.Name or "Unknown",
												TextColor3 = Color3.fromRGB(255, 200, 100),
												TextSize = 16,
												TextXAlignment = Enum.TextXAlignment.Left,
												LayoutOrder = 1,
												FontFace = Font.new(
													"rbxassetid://11702779517",
													Enum.FontWeight.Bold,
													Enum.FontStyle.Normal
												),
											}),

											MessageLabel = e("TextLabel", {
												Size = UDim2.fromScale(1, 0), -- Full width
												AutomaticSize = Enum.AutomaticSize.Y,
												BackgroundTransparency = 1,
												Text = entry.Message,
												TextColor3 = Color3.new(1, 1, 1),
												TextSize = 16,

												-- Fix spacing issues
												RichText = true,
												LineHeight = 1,

												TextWrapped = true,
												TextXAlignment = Enum.TextXAlignment.Left,
												TextYAlignment = Enum.TextYAlignment.Top,
												LayoutOrder = 2,
												FontFace = Font.new(
													"rbxassetid://11702779517",
													Enum.FontWeight.Medium,
													Enum.FontStyle.Normal
												),
											}),
										}),
									})
								else
									-- SYSTEM MESSAGE (Text Only)
									children["Log_" .. i] = e("TextLabel", {
										Size = UDim2.new(1, 0, 0, 18),
										BackgroundTransparency = 1,
										Text = tostring(entry),
										TextColor3 = Color3.fromRGB(200, 200, 220),
										TextScaled = true,
										TextWrapped = true,
										TextXAlignment = Enum.TextXAlignment.Left,
										LayoutOrder = i,
										FontFace = Font.new(
											"rbxassetid://11702779517",
											Enum.FontWeight.Bold,
											Enum.FontStyle.Normal
										),
									})
								end
							end

							return children
						end)()
					),
				}),

				-- DIVIDER
				Divider = not isSpectator and e("Frame", {
					Size = UDim2.fromScale(0.9, 0.005),
					Position = UDim2.fromScale(0.5, 0.935),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 0.5,
				}, {
					UICorner = e("UICorner", {
						CornerRadius = UDim.new(10, 0),
					}),
				}) or nil,

				-- CHAT INPUT (Bottom 14%)
				ChatContainer = not isSpectator
						and e("Frame", {
							Size = UDim2.fromScale(1, 0.05),
							Position = UDim2.fromScale(0, 0.95),
							BackgroundTransparency = 1,
						}, {
							UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
								AspectRatio = 10,
							}),

							UIPadding = e("UIPadding", {
								PaddingTop = UDim.new(0.1, 0),
								PaddingLeft = UDim.new(0.05, 0),
								PaddingRight = UDim.new(0.05, 0),
								PaddingBottom = UDim.new(0.1, 0),
							}),

							InputContainer = e("ScrollingFrame", {
								Size = UDim2.fromScale(0.78, 1),
								Position = UDim2.fromScale(0, 0.5),
								AnchorPoint = Vector2.new(0, 0.5),
								BackgroundColor3 = Color3.fromRGB(0, 0, 0),
								BackgroundTransparency = 0.5,
								ScrollBarThickness = 0.5,
								ScrollBarImageColor3 = Color3.fromRGB(249, 0, 149),
								AutomaticCanvasSize = Enum.AutomaticSize.Y,
							}, {
								UICorner = e("UICorner", { CornerRadius = UDim.new(0.3, 0) }),

								TextBox = e("TextBox", {
									Size = UDim2.fromScale(0.9, 0.5),
									Position = UDim2.fromScale(0.5, 0.5),
									AnchorPoint = Vector2.new(0.5, 0.5),
									BackgroundTransparency = 1,
									Text = "",
									PlaceholderText = "Chat...",
									PlaceholderColor3 = Color3.fromRGB(200, 200, 200),
									TextColor3 = Color3.new(1, 1, 1),
									TextSize = 14,
									MultiLine = false,
									ClearTextOnFocus = false,
									ref = chatInputRef,
									TextXAlignment = Enum.TextXAlignment.Left,
									TextYAlignment = Enum.TextYAlignment.Top,
									FontFace = Font.new(
										"rbxassetid://11702779517",
										Enum.FontWeight.Medium,
										Enum.FontStyle.Normal
									),
									[React.Change.Text] = function(rbx)
										local text = rbx.Text
										if #text > 200 then
											text = string.sub(text, 1, 200)
											rbx.Text = text
										end
										setChatMessage(text)
									end,
									[React.Event.FocusLost] = function(rbx, enterPressed)
										-- Check for non-whitespace content
										if enterPressed and chatMessage:match("%S") then
											-- Spam prevention
											if not checkSpam() then
												return
											end

											ScrabbleServiceClient:sendMessage(chatMessage)
											setChatMessage("")
											rbx.Text = ""
											task.defer(function()
												rbx:CaptureFocus()
											end)
										end
									end,
								}),
							}),

							SendButton = e(TextButton, {
								Text = isBlocked and "WAIT" or "SEND",
								Variant = isBlocked and "secondary" or "primary",
								Size = UDim2.fromScale(0.2, 1),
								Position = UDim2.fromScale(1, 0.5),
								AnchorPoint = Vector2.new(1, 0.5),
								Disabled = not chatMessage:match("%S") or isBlocked,
								OnClick = function()
									if chatMessage:match("%S") then
										-- Spam prevention
										if not checkSpam() then
											return
										end

										ScrabbleServiceClient:sendMessage(chatMessage)
										setChatMessage("")
										if chatInputRef.current then
											chatInputRef.current.Text = ""
										end
									end
								end,
							}),
						})
					or nil,
			}),
		}),

		EndScreenOverlay = (gameState.Phase == "ended" or forceShowEndScreen)
				and e(EndScreen, {
					GameState = gameState,
					LobbyState = lobbyState,
					OnLeave = props.OnLeave,
					IsEliminated = forceShowEndScreen, -- True when eliminated player views stats early
				})
			or nil,

		-- End game announcement (shows reason: tiles placed, time out, all passed)
		EndGameAnnouncementUI = (gameState.Phase == "endingGame" or gameState.Phase == "ended")
				and gameState.EndingMessage
				and e(EndGameAnnouncement, {
					key = gameState.EndingMessage, -- Unique key forces remount for animation
					Message = gameState.EndingMessage,
				})
			or nil,

		-- Note: Penalty animation is handled by the useEffect in lines 726-791
		-- which does tick-by-tick score subtraction with particles
		-- Render all active turn announcements (each with independent lifecycle)
		TurnAnnouncementsContainer = #announcements > 0 and e(
			"Folder",
			{},
			(function()
				local announcementElements = {}
				for i, ann in ipairs(announcements) do
					announcementElements["TurnAnnouncement_" .. i] = e(TurnAnnouncement, {
						key = ann.Key,
						PlayerName = ann.Name,
						IsLocal = ann.IsLocal,
					})
				end
				return announcementElements
			end)()
		) or nil,

		-- Elimination screen for players who ran out of time
		EliminationOverlay = (function()
			-- Check if local player is eliminated and hasn't chose to spectate
			-- Note: Network serialization may convert numeric keys to strings, so check both
			local isEliminated = gameState.EliminatedPlayers
				and (
					gameState.EliminatedPlayers[LocalPlayer.UserId]
					or gameState.EliminatedPlayers[tostring(LocalPlayer.UserId)]
				)
			-- Don't show if game ended, already spectating, or viewing stats
			if not isEliminated or gameState.Phase == "ended" or isSpectator or forceShowEndScreen then
				return nil
			end
			return e(EliminationScreen, {
				Visible = true,
				GameState = gameState,
				OnSpectate = function()
					-- Force into spectator mode locally
					setForceSpectatorMode(true)
				end,
				OnViewStats = function()
					-- Show end screen with current stats
					setForceShowEndScreen(true)
				end,
				OnLeave = props.OnLeave,
			})
		end)(),

		-- Blank tile letter picker modal
		BlankTileModalUI = pendingBlankPosition
				and e(BlankTileModal, {
					OnSelect = function(selectedLetter)
						-- Save the blank assignment
						local posKey = pendingBlankPosition.row .. "," .. pendingBlankPosition.col
						setBlankAssignments(function(prev)
							local newAssignments = table.clone(prev)
							newAssignments[posKey] = selectedLetter
							return newAssignments
						end)

						-- Update the placed tile to show the selected letter
						setPlacedTiles(function(prev)
							local newPlaced = {}
							for _, p in ipairs(prev) do
								if p.row == pendingBlankPosition.row and p.col == pendingBlankPosition.col then
									table.insert(newPlaced, {
										row = p.row,
										col = p.col,
										letter = selectedLetter, -- Show the assigned letter
										rackIndex = p.rackIndex,
									})
								else
									table.insert(newPlaced, p)
								end
							end
							return newPlaced
						end)

						setPendingBlankPosition(nil)
					end,
					OnCancel = function()
						-- Remove the blank tile from placed tiles
						setPlacedTiles(function(prev)
							local newPlaced = {}
							for _, p in ipairs(prev) do
								if not (p.row == pendingBlankPosition.row and p.col == pendingBlankPosition.col) then
									table.insert(newPlaced, p)
								end
							end
							return newPlaced
						end)
						setPendingBlankPosition(nil)
					end,
				})
			or nil,

		ResignConfirmModal = showResignConfirm and e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.5,
			ZIndex = 20000,
		}, {
			Modal = e("Frame", {
				Size = UDim2.fromScale(0.4, 0.35),
				Position = UDim2.fromScale(0.5, 0.4),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(35, 40, 65),
				BorderSizePixel = 0,
			}, {
				UICorner = e("UICorner", { CornerRadius = UDim.new(0, 12) }),
				UIStroke = e("UIStroke", { Color = Color3.fromRGB(249, 0, 149), Thickness = 3 }),

				Content = e("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
				}, {
					UIPadding = e("UIPadding", {
						PaddingTop = UDim.new(0.1, 0),
						PaddingBottom = UDim.new(0.1, 0),
						PaddingLeft = UDim.new(0.05, 0),
						PaddingRight = UDim.new(0.05, 0),
					}),
					UIListLayout = e("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0.1, 0),
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
					}),

					Title = e("TextLabel", {
						Size = UDim2.fromScale(1, 0.2),
						BackgroundTransparency = 1,
						Text = "LEAVE GAME?",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
						FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
						LayoutOrder = 1,
					}),

					Warning = e("TextLabel", {
						Size = UDim2.fromScale(1, 0.3),
						BackgroundTransparency = 1,
						Text = "Leaving an active game will penalize you 50 Coins and end your turn. Are you sure?",
						TextColor3 = Color3.fromRGB(255, 100, 100),
						TextWrapped = true,
						TextScaled = true,
						FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium),
						LayoutOrder = 2,
					}),

					Buttons = e("Frame", {
						Size = UDim2.fromScale(1, 0.3),
						BackgroundTransparency = 1,
						LayoutOrder = 3,
					}, {
						UIListLayout = e("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = UDim.new(0.05, 0),
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
						}),

						Cancel = e(TextButton, {
							Text = "Stay",
							Variant = "secondary",
							Size = UDim2.fromScale(0.45, 1),
							OnClick = function()
								setShowResignConfirm(false)
							end,
						}),

						Confirm = e(TextButton, {
							Text = "Leave & Pay",
							Variant = "primary",
							Size = UDim2.fromScale(0.45, 1),
							OnClick = confirmResign,
						}),
					}),
				}),
			}),
		}) or nil,

		-- Word Submit Confirmation Modal
		SubmitConfirmModal = showSubmitConfirm
				and e("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.new(0, 0, 0),
					BackgroundTransparency = 0.5,
					ZIndex = 110, -- Slightly above other modals
				}, {
					Dialog = e("Frame", {
						Size = UDim2.fromScale(0.3, 0.25),
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(40, 60, 100),
					}, {
						UICorner = e("UICorner", { CornerRadius = UDim.new(0.05, 0) }),
						UIStroke = e("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }),
						UIPadding = e("UIPadding", {
							PaddingBottom = UDim.new(0.05, 0),
							PaddingTop = UDim.new(0.05, 0),
							PaddingLeft = UDim.new(0.05, 0),
							PaddingRight = UDim.new(0.05, 0),
						}),

						UIListLayout = e("UIListLayout", {
							FillDirection = Enum.FillDirection.Vertical,
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = UDim.new(0.1, 0),
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
						}),

						Title = e("TextLabel", {
							Size = UDim2.fromScale(1, 0.25),
							BackgroundTransparency = 1,
							Text = "PLAY WORD?",
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							FontFace = Font.new(
								"rbxassetid://11702779517",
								Enum.FontWeight.Heavy,
								Enum.FontStyle.Italic
							),
							LayoutOrder = 1,
						}),

						Warning = e("TextLabel", {
							Size = UDim2.fromScale(1, 0.35),
							BackgroundTransparency = 1,
							Text = "Are you sure you want to play this word for "
								.. (wordValidation.score or 0)
								.. " points?",
							TextColor3 = Color3.new(1, 1, 1),
							TextWrapped = true,
							TextScaled = true,
							FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium),
							LayoutOrder = 2,
						}),

						Buttons = e("Frame", {
							Size = UDim2.fromScale(1, 0.3),
							BackgroundTransparency = 1,
							LayoutOrder = 3,
						}, {
							UIListLayout = e("UIListLayout", {
								FillDirection = Enum.FillDirection.Horizontal,
								SortOrder = Enum.SortOrder.LayoutOrder,
								Padding = UDim.new(0.05, 0),
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
							}),

							Cancel = e(TextButton, {
								Text = "Cancel",
								Variant = "secondary",
								Size = UDim2.fromScale(0.45, 1),
								OnClick = function()
									setShowSubmitConfirm(false)
								end,
							}),

							Confirm = e(TextButton, {
								Text = "Play",
								Variant = "primary",
								Size = UDim2.fromScale(0.45, 1),
								OnClick = handleSubmit,
							}),
						}),
					}),
				})
			or nil,

		-- First game tutorial helper (shows hints for new players)
		FirstGameHelperUI = showTutorialHelper
				and not isSpectator
				and gameState
				and gameState.Phase == "inGame"
				and isMyTurn
				and e(FirstGameHelper, {
					Rack = myRack,
					PlacedTiles = placedTiles,
					PlacedTilesCount = #placedTiles,
					-- Force "IsBoardEmpty" to true so tutorial shows on my first turn
					-- even if bots have played (user request)
					IsBoardEmpty = true,
					BoardPositions = tileAbsolutePositions.current,
					RackPositions = rackTilePositions.current,
					PlayButtonPosition = playButtonPos,
					OnDismiss = function()
						setShowTutorialHelper(false)
						SettingsServiceClient:completeTutorial()
					end,
				})
			or nil,
	})
end
