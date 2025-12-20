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

	-- Local placement state
	local selectedTileIndex, setSelectedTileIndex = React.useState(nil :: number?)
	local placedTiles, setPlacedTiles =
		React.useState({} :: { { row: number, col: number, letter: string, rackIndex: number } })

	-- Drag and drop state
	local draggingIndex, setDraggingIndex = React.useState(nil :: number?)
	local draggingLetter, setDraggingLetter = React.useState(nil :: string?)
	local dragHoverCell, setDragHoverCell = React.useState(nil :: { row: number, col: number }?)
	local lastHoverPos = React.useRef(nil :: string?)

	-- Exchange mode state
	local isExchangeMode, setIsExchangeMode = React.useState(false)
	-- Track exchange selection with rack indices instead of display indices
	local exchangeSelection, setExchangeSelection = React.useState({} :: { [number]: boolean })
	-- Track tiles that were on the board but were selected for exchange
	local stashedTiles, setStashedTiles =
		React.useState({} :: { [number]: { row: number, col: number, letter: string, rackIndex: number } })

	-- Spam Block State
	local isBlocked, setIsBlocked = React.useState(false)

	-- Chat state
	local chatMessage, setChatMessage = React.useState("")
	local chatInputRef = React.useRef(nil :: TextBox?)
	local logScrollRef = React.useRef(nil :: ScrollingFrame?)

	-- Visual scoreboard state (decoupled from server)
	local visualScores, setVisualScores = React.useState({} :: { [string]: number })

	-- Score animation state
	local playerGoalPositions = React.useRef({} :: { [number]: Vector2 })
	local tileAbsolutePositions = React.useRef({} :: { [string]: Vector2 })
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
	local isSpectator = gameState and gameState.IsSpectator == true
	local tilesInBag = if gameState then (gameState.BagCount or 0) else 0
	local currentTurnUserId = if gameState then (gameState.TurnUserId or turnOrder[turnIndex]) else nil

	-- Delayed turn switch for animations
	local visualTurnUserId, setVisualTurnUserId = React.useState(currentTurnUserId)
	local lastActualTurnUserId = React.useRef(currentTurnUserId)

	React.useEffect(function()
		if currentTurnUserId ~= lastActualTurnUserId.current then
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

	-- Track which tiles are placed or exchanged
	local hiddenIndices = {}

	-- Mark placed tiles as hidden
	for _, placed in ipairs(placedTiles) do
		hiddenIndices[placed.rackIndex] = true
	end

	-- Mark exchanged tiles as hidden in exchange mode
	if isExchangeMode then
		for i, selected in pairs(exchangeSelection) do
			if selected then
				hiddenIndices[i] = true
			end
		end
	end

	-- Build display rack maintaining original order
	local displayRack = {}
	local rackIndexToDisplayIndex = {}
	local displayIndex = 1

	for i = 1, #myRack do
		if not hiddenIndices[i] then
			table.insert(displayRack, myRack[i])
			rackIndexToDisplayIndex[i] = displayIndex
			displayIndex += 1
		end
	end

	-- Get the display index for the currently dragging tile
	local draggingDisplayIndex = draggingIndex and rackIndexToDisplayIndex[draggingIndex] or nil

	-- Build display board (merge server board with local placements)
	local displayBoard = {}
	for r = 1, 15 do
		displayBoard[r] = {}
		for c = 1, 15 do
			displayBoard[r][c] = board[r] and board[r][c] or nil
		end
	end

	local previewCells = {}
	for _, placed in ipairs(placedTiles) do
		displayBoard[placed.row][placed.col] = placed.letter
		table.insert(previewCells, { row = placed.row, col = placed.col })
	end

	-- Word validation (MUST be called before any early returns)
	local wordValidation = useWordValidator(placedTiles, board)

	-- Turn Notification logic
	local lastTurnUserId = React.useRef(nil)
	local turnAnnouncement, setTurnAnnouncement = React.useState(nil :: { Name: string, IsLocal: boolean }?)

	React.useEffect(function()
		if
			gameState
			and gameState.Phase == "inGame"
			and visualTurnUserId
			and visualTurnUserId ~= lastTurnUserId.current
		then
			lastTurnUserId.current = visualTurnUserId

			-- Only show turn announcement in multiplayer
			-- Solo play uses a separate score-based trigger for encouragement
			if #turnOrder > 1 then
				-- Find player name
				local name = "Unknown"
				if lobbyState and lobbyState.Players then
					for _, p in ipairs(lobbyState.Players) do
						if p.UserId == currentTurnUserId then
							name = p.Name
							break
						end
					end
				end

				setTurnAnnouncement({
					Name = name,
					IsLocal = currentTurnUserId == LocalPlayer.UserId,
					IsSolo = false, -- Multiplayer doesn't use encouragement phrases
				})
			end

			-- Clear after animation duration
			task.delay(3, function()
				setTurnAnnouncement(nil)
			end)
		end
	end, { visualTurnUserId })

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
	for _, oderId in ipairs(turnOrder) do
		-- userId might be string or number after network transfer
		local userId = tonumber(oderId) or oderId
		local player = Players:GetPlayerByUserId(userId)
		table.insert(playerScores, {
			UserId = userId,
			Name = player and player.Name or ("Player " .. tostring(userId)),
			Score = getScore(userId),
			IsCurrentTurn = userId == visualTurnUserId or tostring(userId) == tostring(visualTurnUserId),
			TimeRemaining = getPlayerTime(userId),
		})
	end

	-- Solo Play Encouragement Trigger (Score based)
	local lastMyScore = React.useRef(0)

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
							local placedTiles = lastMove.PlacedTiles or {}
							local totalScore = lastMove.TotalScore or 0
							local tileCount = #placedTiles

							if tileCount > 0 then
								local tilesToAnimate = {}
								local scorePerTile = math.floor(totalScore / tileCount)
								local remainder = totalScore % tileCount

								for i, tile in ipairs(placedTiles) do
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

	React.useEffect(function()
		if #turnOrder == 1 and gameState and gameState.Phase == "inGame" then
			local currentScore = getScore(LocalPlayer.UserId)
			if currentScore > lastMyScore.current then
				lastMyScore.current = currentScore

				-- Trigger announcement
				setTurnAnnouncement({
					Name = LocalPlayer.Name,
					IsLocal = true,
					IsSolo = true,
				})

				task.delay(3, function()
					setTurnAnnouncement(nil)
				end)
			elseif currentScore < lastMyScore.current then
				-- Reset (e.g. game restart)
				lastMyScore.current = currentScore
			end
		end
	end, { scores })

	-- Handlers
	local function handleTileClick(index: number, _: string)
		if selectedTileIndex == index then
			setSelectedTileIndex(nil)
		else
			setSelectedTileIndex(index)
		end
	end

	-- Drag handlers
	local function handleDragStart(index: number, letter: string)
		-- Find actual rack index
		local actualIndex = 0
		local count = 0
		for i, _ in ipairs(myRack) do
			if not hiddenIndices[i] then
				count += 1
				if count == index then
					actualIndex = i
					break
				end
			end
		end

		if actualIndex > 0 then
			setDraggingIndex(actualIndex)
			setDraggingLetter(letter)
			setSelectedTileIndex(nil)
		end
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
			-- Start dragging this tile
			setDraggingIndex(rackIndex)
			setDraggingLetter(letter)
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
					elseif type == "rack" then
						cancelDrag() -- Dropped back to rack
					end

					cancelDrag() -- Dropped outside
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
				return
			end
		end

		-- Find the actual rack index for the selected tile
		local actualIndex = 0
		local count = 0
		for i, _ in ipairs(myRack) do
			if not hiddenIndices[i] then
				count += 1
				if count == selectedTileIndex then
					actualIndex = i
					break
				end
			end
		end

		if actualIndex == 0 then
			return
		end

		-- Place the tile
		local newPlaced = {}
		for _, p in ipairs(placedTiles) do
			table.insert(newPlaced, p)
		end
		table.insert(newPlaced, {
			row = row,
			col = col,
			letter = myRack[actualIndex],
			rackIndex = actualIndex,
		})
		setPlacedTiles(newPlaced)
		setSelectedTileIndex(nil)
	end

	local function handleClear()
		setPlacedTiles({})
		setSelectedTileIndex(nil)
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

		-- Send placed tiles to server
		ScrabbleServiceClient:placeWord(placedTiles, wordValidation.direction)

		-- Clear local state
		handleClear()
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

			-- Find all selected tiles by their rack indices
			for rackIndex, selected in pairs(exchangeSelection) do
				if selected and myRack[rackIndex] then
					table.insert(lettersToExchange, myRack[rackIndex])
					table.insert(exchangeIndices, rackIndex)
				end
			end

			if #lettersToExchange > 0 then
				-- Store which positions are being exchanged to maintain order
				local exchangeData = {
					Letters = lettersToExchange,
					Indices = exchangeIndices,
				}

				ScrabbleServiceClient:exchangeTiles(exchangeData)
			end

			-- Exit exchange mode
			setIsExchangeMode(false)
			setExchangeSelection({})
			setStashedTiles({})
		else
			-- Enter exchange mode
			setIsExchangeMode(true)
			setExchangeSelection({})
			setStashedTiles({})
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

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	}, {
		UIGradient = e("UIGradient", {
			Color = hue:map(function(h)
				return ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(h, 0.7, 0.2)), -- Dark, saturated blue
					ColorSequenceKeypoint.new(1, Color3.fromHSV((h + 0.05) % 1, 0.7, 0.1)),
				})
			end),
			Rotation = rotation,
		}),

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
						IsWordValid = wordValidation.isValid,
						DragHoverCell = dragHoverCell,
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
								-- In exchange mode, show full rack; otherwise show display rack
								Letters = if isExchangeMode then myRack else displayRack,
								SelectedIndex = selectedTileIndex,
								DraggingIndex = draggingDisplayIndex,
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
							})
						or e("TextLabel", {
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
							Text = "SPECTATING",
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
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
						OnCancelExchange = handleCancelExchange,
						OnClear = handleClear,
						CanPass = #turnOrder > 1,
					}) or e("Frame", {
						Size = UDim2.fromScale(0.25, 1),
						Position = UDim2.fromScale(0.5, 0),
						AnchorPoint = Vector2.new(0.5, 0),
						BackgroundTransparency = 1,
					}, {
						LeaveButton = e(TextButton, {
							Text = "Leave",
							Variant = "secondary",
							Size = UDim2.fromScale(1, 1),
							OnClick = function()
								if props.OnLeave then
									props.OnLeave()
								end
								ScrabbleServiceClient:leaveLobby()
							end,
						}),

						UIPadding = e("UIPadding", {
							PaddingBottom = UDim.new(0.3, 0),
						}),
					}),
				}),
			}),

			-- RightPanel: Game log / chat
			RightPanel = e("Frame", {
				Size = UDim2.fromScale(0.18, 1),
				BackgroundColor3 = Color3.fromRGB(30, 45, 90), -- Match GameBoard
				LayoutOrder = 3,
			}, {
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
						},
						(function()
							local children = {
								UIListLayout = e("UIListLayout", {
									SortOrder = Enum.SortOrder.LayoutOrder,
									VerticalAlignment = Enum.VerticalAlignment.Bottom,
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

							local log = processedLog

							for i, entry in ipairs(log) do
								if type(entry) == "table" and entry.UserId and entry.Message then
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
											Size = UDim2.fromOffset(30, 30), -- Fixed size avatar
											Position = UDim2.fromOffset(0, 0),
											BackgroundTransparency = 1,
											Image = "rbxthumb://type=AvatarHeadShot&id="
												.. entry.UserId
												.. "&w=150&h=150",
										}, {
											UICorner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
											UIStroke = e("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }),
										}),

										Content = e("Frame", {
											Size = UDim2.fromScale(1, 0),
											AutomaticSize = Enum.AutomaticSize.Y,
											Position = UDim2.fromOffset(38, 0), -- Offset by avatar width + gap
											BackgroundTransparency = 1,
										}, {
											UIListLayout = e("UIListLayout", {
												SortOrder = Enum.SortOrder.LayoutOrder,
											}),

											Name = e("TextLabel", {
												Size = UDim2.fromScale(1, 0),
												AutomaticSize = Enum.AutomaticSize.Y,
												BackgroundTransparency = 1,
												Text = entry.Name or "Unknown",
												TextColor3 = Color3.fromRGB(249, 0, 149),
												TextSize = 14,
												Font = Enum.Font.GothamBold,
												TextXAlignment = Enum.TextXAlignment.Left,
												LayoutOrder = 1,
											}),

											Message = e("TextLabel", {
												Size = UDim2.fromScale(0.85, 0), -- Width constraint
												AutomaticSize = Enum.AutomaticSize.Y,
												BackgroundTransparency = 1,
												Text = entry.Message,
												TextColor3 = Color3.new(1, 1, 1),
												TextSize = 14,

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
										Size = UDim2.fromScale(1, 0.03),
										BackgroundTransparency = 1,
										Text = tostring(entry),
										TextColor3 = Color3.fromRGB(200, 200, 220),
										TextSize = 20,
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

		EndScreenOverlay = gameState.Phase == "ended" and e(EndScreen, {
			GameState = gameState,
			LobbyState = lobbyState,
			OnLeave = props.OnLeave,
		}) or nil,

		TurnAnnouncementUI = turnAnnouncement and e(TurnAnnouncement, {
			PlayerName = turnAnnouncement.Name,
			IsLocal = turnAnnouncement.IsLocal,
			IsSolo = turnAnnouncement.IsSolo,
		}) or nil,
	})
end
