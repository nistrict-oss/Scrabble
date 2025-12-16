--[[
	Game.luau
	
	Main Scrabble gameplay screen. Contains the board, player rack,
	scoreboard, and game controls.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.React)
local GameBoard = require(ReplicatedStorage.UI.components.game.GameBoard)
local PlayerRack = require(ReplicatedStorage.UI.components.game.PlayerRack)
local ScoreBoard = require(ReplicatedStorage.UI.components.game.ScoreBoard)
local GameControls = require(ReplicatedStorage.UI.components.game.GameControls)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)
local ScrabbleServiceClient = require(ReplicatedStorage.Shared.Services.ScrabbleService.ScrabbleServiceClient)
local DragPreview = require(ReplicatedStorage.UI.components.game.DragPreview)
local WordValidationDisplay = require(ReplicatedStorage.UI.components.game.WordValidationDisplay)
local useWordValidatorHook = require(ReplicatedStorage.UI.hooks.useWordValidator)

local e = React.createElement
local useWordValidator = useWordValidatorHook.useWordValidator

local LocalPlayer = Players.LocalPlayer

export type GameProps = {
	GameState: any,
	LobbyState: any,
	OnLeave: (() -> ())?,
}

return function(props: GameProps)
	local gameState = props.GameState
	local lobbyState = props.LobbyState
	
	-- Debug: Log when game state changes
	React.useEffect(function()
		if gameState and gameState.Board then
			local letterCount = 0
			for r = 1, 15 do
				if gameState.Board[r] then
					for c = 1, 15 do
						if gameState.Board[r][c] then
							letterCount += 1
						end
					end
				end
			end
			print("[Game Component] Received gameState with", letterCount, "letters on board")
		end
	end, { gameState })
	
	-- Local placement state
	local selectedTileIndex, setSelectedTileIndex = React.useState(nil :: number?)
	local placedTiles, setPlacedTiles = React.useState({} :: { { row: number, col: number, letter: string, rackIndex: number } })
	local placementDirection, setPlacementDirection = React.useState("across" :: "across" | "down")
	
	-- Drag and drop state
	local draggingIndex, setDraggingIndex = React.useState(nil :: number?)
	local draggingLetter, setDraggingLetter = React.useState(nil :: string?)
	local dragHoverCell, setDragHoverCell = React.useState(nil :: { row: number, col: number }?)
	
	-- Exchange mode state
	local isExchangeMode, setIsExchangeMode = React.useState(false)
	local exchangeSelection, setExchangeSelection = React.useState({} :: { [number]: boolean })
	
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
				FontFace = Font.new(
					"rbxassetid://11702779517",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Italic
				),
			}),
		})
	end
	
	-- Check if game ended
	if gameState.Phase == "ended" then
		-- Find winner
		local winnerName = "Unknown"
		local highScore = 0
		if gameState.Scores then
			for userId, score in pairs(gameState.Scores) do
				if score > highScore then
					highScore = score
					local player = Players:GetPlayerByUserId(userId)
					winnerName = player and player.Name or ("Player " .. userId)
				end
			end
		end
		
		return e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(40, 60, 120),
		}, {
			ResultPanel = e("Frame", {
				Size = UDim2.fromScale(0.4, 0.4),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(35, 55, 100),
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0.05, 0),
				}),
				
				UIStroke = e("UIStroke", {
					Color = Color3.new(1, 1, 1),
					Thickness = 3,
				}),
				
				Title = e("TextLabel", {
					Size = UDim2.fromScale(1, 0.25),
					Position = UDim2.fromScale(0, 0.1),
					BackgroundTransparency = 1,
					Text = "Game Over!",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					FontFace = Font.new(
						"rbxassetid://11702779517",
						Enum.FontWeight.Heavy,
						Enum.FontStyle.Italic
					),
				}),
				
				Winner = e("TextLabel", {
					Size = UDim2.fromScale(1, 0.2),
					Position = UDim2.fromScale(0, 0.35),
					BackgroundTransparency = 1,
					Text = winnerName .. " wins!",
					TextColor3 = Color3.fromRGB(249, 0, 149), -- Pink accent
					TextScaled = true,
					FontFace = Font.new(
						"rbxassetid://11702779517",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
				}),
				
				Score = e("TextLabel", {
					Size = UDim2.fromScale(1, 0.15),
					Position = UDim2.fromScale(0, 0.55),
					BackgroundTransparency = 1,
					Text = "Score: " .. highScore,
					TextColor3 = Color3.fromRGB(150, 150, 180),
					TextScaled = true,
					FontFace = Font.new(
						"rbxassetid://11702779517",
						Enum.FontWeight.Medium,
						Enum.FontStyle.Normal
					),
				}),
				
				LeaveButton = e("Frame", {
					Size = UDim2.fromScale(0.5, 0.15),
					Position = UDim2.fromScale(0.5, 0.8),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
				}, {
					Button = e(TextButton, {
						Text = "Leave",
						Variant = "primary",
						Size = UDim2.fromScale(1, 1),
						OnClick = function()
							ScrabbleServiceClient:leaveLobby()
							if props.OnLeave then
								props.OnLeave()
							end
						end,
					}),
				}),
			}),
		})
	end
	
	-- Game data
	local board = gameState.Board or {}
	local myRack = gameState.Rack or {} -- Server sends Rack directly per player
	local scores = gameState.Scores or {}
	local turnOrder = gameState.TurnOrder or {}
	local turnIndex = gameState.TurnIndex or 1
	local currentTurnUserId = gameState.TurnUserId or (turnOrder[turnIndex])
	local isMyTurn = currentTurnUserId == LocalPlayer.UserId
	local tilesInBag = gameState.BagCount or 0
	
	-- Build display rack (remove placed tiles)
	local displayRack = {}
	local usedIndices = {}
	for _, placed in ipairs(placedTiles) do
		usedIndices[placed.rackIndex] = true
	end
	
	-- Map from myRack index to displayRack index
	local rackIndexToDisplayIndex = {}
	for i, letter in ipairs(myRack) do
		if not usedIndices[i] then
			table.insert(displayRack, letter)
			rackIndexToDisplayIndex[i] = #displayRack
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
	
	-- Word validation
	local wordValidation = useWordValidator(placedTiles, board)
	
	-- Build player scores for ScoreBoard
	-- Helper for score lookup (handles string/number key conversion)
	local function getScore(userId): number
		return scores[userId] or scores[tostring(userId)] or 0
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
			IsCurrentTurn = userId == currentTurnUserId or tostring(userId) == tostring(currentTurnUserId),
		})
	end
	
	-- Handlers
	local function handleTileClick(index: number, letter: string)
		if not isMyTurn then return end
		
		if selectedTileIndex == index then
			setSelectedTileIndex(nil)
		else
			setSelectedTileIndex(index)
		end
	end
	
	-- Drag handlers
	local function handleDragStart(index: number, letter: string)
		if not isMyTurn then return end
		
		-- Find actual rack index
		local actualIndex = 0
		local count = 0
		for i, _ in ipairs(myRack) do
			if not usedIndices[i] then
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
		if not draggingLetter then return end
		-- Only allow drop on empty cells
		if board[row] and board[row][col] then return end
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
		if not isMyTurn then return end
		
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
	
	-- Global mouse up handler to cancel drag if dropped outside board
	local UserInputService = game:GetService("UserInputService")
	React.useEffect(function()
		if not draggingLetter then
			return
		end
		
		local conn = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				-- Small delay to allow drop handler to fire first
				task.delay(0.05, function()
					if draggingLetter then
						cancelDrag()
					end
				end)
			end
		end)
		
		return function()
			conn:Disconnect()
		end
	end, { draggingLetter })
	
	local function handleCellClick(row: number, col: number)
		if not isMyTurn then return end
		if not selectedTileIndex then return end
		
		-- Check if cell is already occupied (on server board)
		if board[row] and board[row][col] then return end
		
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
			if not usedIndices[i] then
				count += 1
				if count == selectedTileIndex then
					actualIndex = i
					break
				end
			end
		end
		
		if actualIndex == 0 then return end
		
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
		if #placedTiles == 0 then return end
		
		-- Check validation before submitting
		if not wordValidation.isValid then
			print("[Game] Cannot submit - word is invalid:", wordValidation.error or "unknown error")
			return
		end
		
		print("[Game] Submitting word:", wordValidation.word, "direction:", wordValidation.direction, "score:", wordValidation.score)
		
		-- Send placed tiles to server
		ScrabbleServiceClient:placeWord(placedTiles, wordValidation.direction)
		
		-- Clear local state
		handleClear()
	end
	
	local function handlePass()
		ScrabbleServiceClient:passTurn()
		handleClear()
	end
	
	local function handleExchange()
		if isExchangeMode then
			-- Confirm exchange - send selected tiles to server
			local lettersToExchange = {}
			for i, selected in pairs(exchangeSelection) do
				if selected and myRack[i] then
					table.insert(lettersToExchange, myRack[i])
				end
			end
			
			if #lettersToExchange > 0 then
				print("[Game] Exchanging tiles:", table.concat(lettersToExchange, ", "))
				ScrabbleServiceClient:exchangeTiles(lettersToExchange)
			end
			
			-- Exit exchange mode
			setIsExchangeMode(false)
			setExchangeSelection({})
		else
			-- Enter exchange mode
			handleClear() -- Clear any placed tiles
			setIsExchangeMode(true)
			setExchangeSelection({})
		end
	end
	
	local function handleCancelExchange()
		setIsExchangeMode(false)
		setExchangeSelection({})
	end
	
	local function toggleExchangeTile(rackIndex: number)
		setExchangeSelection(function(prev)
			local newSelection = {}
			for k, v in pairs(prev) do
				newSelection[k] = v
			end
			newSelection[rackIndex] = not newSelection[rackIndex]
			return newSelection
		end)
	end
	
	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(40, 60, 120),
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
					}),
				}),
				
				-- Rack
				RackContainer = e("Frame", {
					Size = UDim2.fromScale(0.8, 0.1),
					Position = UDim2.fromScale(0.5, 0.84),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundTransparency = 1,
				}, {
					Rack = e(PlayerRack, {
						-- In exchange mode, show full rack; otherwise show display rack
						Letters = if isExchangeMode then myRack else displayRack,
						SelectedIndex = selectedTileIndex,
						DraggingIndex = draggingDisplayIndex,
						IsDragging = draggingLetter ~= nil,
						IsDisabled = not isMyTurn,
						IsExchangeMode = isExchangeMode,
						ExchangeSelection = exchangeSelection,
						OnTileClick = handleTileClick,
						OnDragStart = handleDragStart,
						OnDropToRack = cancelDrag,
						OnExchangeToggle = toggleExchangeTile,
					}),
				}),
				
				-- Controls
				ControlsContainer = e("Frame", {
					Size = UDim2.fromScale(0.9, 0.08),
					Position = UDim2.fromScale(0.5, 0.95),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundTransparency = 1,
				}, {
					Controls = e(GameControls, {
						IsMyTurn = isMyTurn,
						CanSubmit = #placedTiles > 0 and wordValidation.isValid,
						IsExchangeMode = isExchangeMode,
						ExchangeCount = (function()
							local count = 0
							for _, selected in pairs(exchangeSelection) do
								if selected then count += 1 end
							end
							return count
						end)(),
						OnSubmit = handleSubmit,
						OnPass = handlePass,
						OnExchange = handleExchange,
						OnCancelExchange = handleCancelExchange,
						OnClear = handleClear,
					}),
				}),
			}),
			
			-- Right panel: Game log / chat
			RightPanel = e("Frame", {
				Size = UDim2.fromScale(0.18, 1),
				BackgroundColor3 = Color3.fromRGB(35, 55, 100),
				LayoutOrder = 3,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0.03, 0),
				}),
				
				UIStroke = e("UIStroke", {
					Color = Color3.new(1, 1, 1),
					Thickness = 2,
				}),
				
				Header = e("TextLabel", {
					Size = UDim2.fromScale(1, 0.05),
					BackgroundTransparency = 1,
					Text = "GAME LOG",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					FontFace = Font.new(
						"rbxassetid://11702779517",
						Enum.FontWeight.Heavy,
						Enum.FontStyle.Italic
					),
				}, {
					UIPadding = e("UIPadding", {
						PaddingTop = UDim.new(0.3, 0),
					}),
				}),
				
				LogScroll = e("ScrollingFrame", {
					Size = UDim2.fromScale(0.9, 0.9),
					Position = UDim2.fromScale(0.5, 0.55),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					ScrollBarThickness = 4,
					ScrollBarImageColor3 = Color3.fromRGB(249, 0, 149),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					CanvasSize = UDim2.fromScale(0, 0),
				}, (function()
					local children = {
						UIListLayout = e("UIListLayout", {
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = UDim.new(0, 5),
						}),
					}
					
					-- Log entries
					local log = gameState.Log or {}
					for i, entry in ipairs(log) do
						children["Log_" .. i] = e("TextLabel", {
							Size = UDim2.new(1, 0, 0, 25),
							BackgroundTransparency = 1,
							Text = entry,
							TextColor3 = Color3.fromRGB(180, 180, 200),
							TextWrapped = true,
							TextXAlignment = Enum.TextXAlignment.Left,
							LayoutOrder = i,
							FontFace = Font.new(
								"rbxassetid://11702779517",
								Enum.FontWeight.Medium,
								Enum.FontStyle.Normal
							),
						})
					end
					
					return children
				end)()),
			}),
		}),
	})
end

