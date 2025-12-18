--[[
	Game.luau
	
	Main Scrabble gameplay screen. Contains the board, player rack,
	scoreboard, and game controls.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage.Packages.React)
local GameBoard = require(ReplicatedStorage.UI.components.game.GameBoard)
local PlayerRack = require(ReplicatedStorage.UI.components.game.PlayerRack)
local ScoreBoard = require(ReplicatedStorage.UI.components.game.ScoreBoard)
local GameControls = require(ReplicatedStorage.UI.components.game.GameControls)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)
local GameConstants = require(ReplicatedStorage.Shared.Modules.Core.GameConstants)
local ScrabbleServiceClient = require(ReplicatedStorage.Shared.Services.ScrabbleService.ScrabbleServiceClient)
local DragPreview = require(ReplicatedStorage.UI.components.game.DragPreview)
local WordValidationDisplay = require(ReplicatedStorage.UI.components.game.WordValidationDisplay)
local useWordValidatorHook = require(ReplicatedStorage.UI.hooks.useWordValidator)
local EndScreen = require(ReplicatedStorage.UI.screens.GameScreen.EndScreen)

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
	-- Track exchange selection with rack indices instead of display indices
	local exchangeSelection, setExchangeSelection = React.useState({} :: { [number]: boolean })
	
	-- Chat state
	local chatMessage, setChatMessage = React.useState("")
	local chatHeight, setChatHeight = React.useState(50)
	local chatInputRef = React.useRef(nil)
	
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
	
	
	-- Game data
	local board = if gameState then (gameState.Board or {}) else {}
	local myRack = if gameState then (gameState.Rack or {}) else {} -- Server sends Rack directly per player
	local scores = if gameState then (gameState.Scores or {}) else {}
	local turnOrder = if gameState then (gameState.TurnOrder or {}) else {}
	local turnIndex = if gameState then (gameState.TurnIndex or 1) else 1
	local currentTurnUserId = if gameState then (gameState.TurnUserId or (turnOrder[turnIndex])) else nil
	local isMyTurn = currentTurnUserId == LocalPlayer.UserId
	local tilesInBag = if gameState then (gameState.BagCount or 0) else 0
	
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
	
	-- Build player scores for ScoreBoard
	-- Helper for score lookup (handles string/number key conversion)
	local function getScore(userId): number
		return scores[userId] or scores[tostring(userId)] or 0
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
			IsCurrentTurn = userId == currentTurnUserId or tostring(userId) == tostring(currentTurnUserId),
			TimeRemaining = getPlayerTime(userId),
		})
	end
	
	-- Handlers
	local function handleTileClick(index: number, letter: string)
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
		if not draggingLetter or not draggingIndex then return end
		
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
			if not hiddenIndices[i] then
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
		if not isMyTurn then return end
		if #placedTiles == 0 then return end
		
		-- Check validation before submitting
		if not wordValidation.isValid then
			return
		end
		
		-- Send placed tiles to server
		ScrabbleServiceClient:placeWord(placedTiles, wordValidation.direction)
		
		-- Clear local state
		handleClear()
	end
	
	local function handlePass()
		if not isMyTurn then return end
		ScrabbleServiceClient:passTurn()
		handleClear()
	end
	
	local function handleExchange()
		if not isMyTurn then return end
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
                Indices = exchangeIndices
            }
            
            ScrabbleServiceClient:exchangeTiles(exchangeData)
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
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	}, {
		UIGradient = e("UIGradient", {
			Color = ColorSequence.new(GameConstants.Gradients.frame),
			Rotation = 90,
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
						Multipliers = wordValidation.multipliers,
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
				
				-- LOG SECTION (Top 85%)
				LogContainer = e("Frame", {
					Size = UDim2.fromScale(1, 0.85),
					BackgroundTransparency = 1,
				}, {
					Header = e("TextLabel", {
						Size = UDim2.fromScale(1, 0.08),
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
							PaddingTop = UDim.new(0.2, 0),
							PaddingBottom = UDim.new(0.1, 0),
						}),
					}),
					
					LogScroll = e("ScrollingFrame", {
						Size = UDim2.fromScale(0.9, 0.9),
						Position = UDim2.fromScale(0.5, 0.1),
						AnchorPoint = Vector2.new(0.5, 0),
						BackgroundTransparency = 1,
						ScrollBarThickness = 4,
						ScrollBarImageColor3 = Color3.fromRGB(249, 0, 149),
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						CanvasSize = UDim2.fromScale(0, 0),
					}, (function()
						local children = {
							UIListLayout = e("UIListLayout", {
								SortOrder = Enum.SortOrder.LayoutOrder,
								Padding = UDim.new(0, 0), -- Remove padding for grouped look
							}),
							UIPadding = e("UIPadding", {
								PaddingLeft = UDim.new(0.02, 0),
								PaddingRight = UDim.new(0.02, 0), 
							}),
						}
						
						-- Log entries
						local log = gameState.Log or {}
						local lastUserId = nil
						
						for i, entry in ipairs(log) do
							if type(entry) == "table" and entry.UserId and entry.Message then
								local isConsecutive = (lastUserId == entry.UserId)
								lastUserId = entry.UserId
								
								-- Extra spacing for new speakers
								local topSpacing = isConsecutive and 0 or 8
								
								-- CHAT MESSAGE (PFP + Name + Text)
								children["Log_" .. i] = e("Frame", {
									Size = UDim2.new(1, 0, 0, 0),
									AutomaticSize = Enum.AutomaticSize.Y,
									BackgroundTransparency = 1,
									LayoutOrder = i,
								}, {
									Avatar = not isConsecutive and e("ImageLabel", {
										Size = UDim2.new(0, 30, 0, 30),
										Position = UDim2.new(0, 0, 0, topSpacing), -- Offset by spacing
										BackgroundTransparency = 1,
										Image = "rbxthumb://type=AvatarHeadShot&id=" .. entry.UserId .. "&w=150&h=150",
									}, {
										UICorner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
										UIStroke = e("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1 }),
									}),
									
									Content = e("Frame", {
										Size = UDim2.new(1, -38, 1, 0),
										Position = UDim2.new(0, 38, 0, topSpacing), -- Offset by spacing
										BackgroundTransparency = 1,
									}, {
										UIListLayout = e("UIListLayout", {
											SortOrder = Enum.SortOrder.LayoutOrder,
											Padding = UDim.new(0, 2),
										}),
										
										Name = not isConsecutive and e("TextLabel", {
											Size = UDim2.new(1, 0, 0, 14),
											BackgroundTransparency = 1,
											Text = entry.Name or "Unknown",
											TextColor3 = Color3.fromRGB(249, 0, 149), -- Pink accent for name
											TextSize = 12,
											TextXAlignment = Enum.TextXAlignment.Left,
											FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
											LayoutOrder = 1,
										}),
										
										Message = e("TextLabel", {
											Size = UDim2.new(1, 0, 0, 0), -- Automatic Height
											AutomaticSize = Enum.AutomaticSize.Y,
											BackgroundTransparency = 1,
											Text = entry.Message,
											TextColor3 = Color3.new(1, 1, 1),
											TextSize = 14,
											TextWrapped = true,
											TextXAlignment = Enum.TextXAlignment.Left,
											LayoutOrder = 2,
											FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
										}),
									}),
								})
							else
								lastUserId = nil -- Reset on system message
								-- SYSTEM MESSAGE (Text Only)
								children["Log_" .. i] = e("TextLabel", {
									Size = UDim2.new(1, 0, 0, 25),
									AutomaticSize = Enum.AutomaticSize.Y,
									BackgroundTransparency = 1,
									Text = tostring(entry),
									TextColor3 = Color3.fromRGB(200, 200, 220),
									TextSize = 14,
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
					end)()),
				}),

				-- DIVIDER
				Divider = e("Frame", {
					Size = UDim2.fromScale(0.9, 0.005),
					Position = UDim2.fromScale(0.5, 0.935),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 0.5,
				}, {
					UICorner = e("UICorner", {
						CornerRadius = UDim.new(1, 0),
					}),
				}),
				
				-- CHAT INPUT (Bottom 14%)
				ChatContainer = e("Frame", {
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
							FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
							[React.Change.Text] = function(rbx)
								local text = rbx.Text
								if #text > 200 then
									text = string.sub(text, 1, 200)
									rbx.Text = text
								end
								setChatMessage(text)
							end,
							[React.Event.FocusLost] = function(rbx, enterPressed)
								if enterPressed and #chatMessage > 0 then
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
						Text = "SEND",
						Variant = "primary",
						Size = UDim2.fromScale(0.2, 1),
						Position = UDim2.fromScale(1, 0.5),
						AnchorPoint = Vector2.new(1, 0.5),
						OnClick = function()
							if #chatMessage > 0 then
								ScrabbleServiceClient:sendMessage(chatMessage)
								setChatMessage("")
							end
						end
					})
				}),
			}),
		}),

		EndScreenOverlay = gameState.Phase == "ended" and e(EndScreen, {
			GameState = gameState,
			LobbyState = lobbyState,
			OnLeave = props.OnLeave,
		}) or nil,
	})
end

