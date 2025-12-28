--[[
	GameBoard.luau
	
	The 15x15 Scrabble board grid. Renders all tiles and handles placement.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local BoardTile = require(ReplicatedStorage.UI.components.game.BoardTile)
local GameConstants = require(ReplicatedStorage.Shared.Modules.Core.GameConstants)

local e = React.createElement

local BOARD_SIZE = 15

export type GameBoardProps = {
	Board: { { { letter: string, colors: { Tile: string, Text: string, Stroke: string } }? } }, -- 15x15 grid of tile data (nil = empty)
	SelectedCell: { row: number, col: number }?,
	PreviewCells: { { row: number, col: number } }?,
	LastMove: { UserId: number, PlacedTiles: { { r: number, c: number } }, TotalScore: number }?,
	LocalUserId: number?, -- Local player's user ID (to filter recent highlights)
	ShowRecentHighlight: boolean?, -- Whether to show recent tile highlights
	IsWordValid: boolean?, -- Whether current placement forms a valid word
	DragHoverCell: { row: number, col: number }?, -- Cell being hovered during drag
	OnCellClick: ((row: number, col: number) -> ())?,
	OnCellDrop: ((row: number, col: number) -> ())?,
	OnCellDragEnter: ((row: number, col: number) -> ())?,
	OnCellDragLeave: ((row: number, col: number) -> ())?,
	OnDragFromBoard: ((row: number, col: number, letter: string) -> ())?,
	OnReportTilePosition: ((row: number, col: number, pos: Vector2) -> ())?,
}

return function(props: GameBoardProps)
	local board = props.Board or {}
	local selectedCell = props.SelectedCell
	local previewCells = props.PreviewCells or {}
	local isWordValid = props.IsWordValid
	local dragHoverCell = props.DragHoverCell

	-- Build preview lookup for fast checking
	local previewLookup = {}
	for _, cell in ipairs(previewCells) do
		previewLookup[cell.row .. "," .. cell.col] = true
	end

	-- Build recent cells lookup for highlighting (only for other players' moves when setting is enabled)
	local lastMove = props.LastMove
	local localUserId = props.LocalUserId
	local showRecentHighlight = props.ShowRecentHighlight == true -- Default to false
	local recentLookup = {}

	-- Only highlight if setting is enabled AND it's not the local player's move
	if showRecentHighlight and lastMove and lastMove.PlacedTiles then
		local isLocalPlayerMove = lastMove.UserId == localUserId
		if not isLocalPlayerMove then
			for _, cell in ipairs(lastMove.PlacedTiles) do
				recentLookup[cell.r .. "," .. cell.c] = true
			end
		end
	end

	-- Create rows
	local rows = {}
	for row = 1, BOARD_SIZE do
		local cells = {}
		for col = 1, BOARD_SIZE do
			local tileData = board[row] and board[row][col]
			local letter = if tileData then tileData.letter else nil
			local tileColors = if tileData then tileData.colors else nil
			local tileIsBlank = if tileData then tileData.isBlank else nil
			local isSelected = selectedCell and selectedCell.row == row and selectedCell.col == col
			local isPreview = previewLookup[row .. "," .. col]
			local isDragHover = dragHoverCell and dragHoverCell.row == row and dragHoverCell.col == col
			local isRecent = recentLookup[row .. "," .. col] and letter and not isPreview

			cells["Cell_" .. col] = e("Frame", {
				Size = UDim2.fromScale(1 / BOARD_SIZE, 1),
				BackgroundTransparency = 1,
				LayoutOrder = col,
			}, {
				[string.format("BoardTile_%d_%d", row, col)] = e(BoardTile, {
					Row = row,
					Col = col,
					Letter = letter,
					TileColors = tileColors, -- Pass the tile owner's colors
					IsBlank = tileIsBlank, -- Pass blank tile status
					IsSelected = isSelected,
					IsPreview = isPreview,
					IsValid = isWordValid,
					IsDragHover = isDragHover,
					IsRecent = isRecent,
					OnClick = props.OnCellClick,
					OnDrop = props.OnCellDrop,
					OnDragEnter = props.OnCellDragEnter,
					OnDragLeave = props.OnCellDragLeave,
					OnDragFromBoard = props.OnDragFromBoard,
					OnReportPosition = props.OnReportTilePosition,
				}),

				UIPadding = e("UIPadding", {
					PaddingBottom = UDim.new(0.03, 0),
					PaddingTop = UDim.new(0.03, 0),
					PaddingLeft = UDim.new(0.03, 0),
					PaddingRight = UDim.new(0.03, 0),
				}),
			})
		end

		cells["UIListLayout"] = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		rows["Row_" .. row] = e("Frame", {
			Size = UDim2.fromScale(1, 1 / BOARD_SIZE),
			BackgroundTransparency = 1,
			LayoutOrder = row,
		}, cells)
	end

	rows["UIListLayout"] = e("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		-- Center the board
		BoardFrame = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ClipsDescendants = true,
		}, {
			UIGradient = e("UIGradient", {
				Color = ColorSequence.new(GameConstants.Gradients.frame),
				Rotation = 90,
			}),
			UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 1,
			}),

			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0.02, 0),
			}),

			UIStroke = e("UIStroke", {
				Color = Color3.new(1, 1, 1),
				Thickness = 3,
			}),

			UIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.01, 0),
				PaddingTop = UDim.new(0.01, 0),
				PaddingLeft = UDim.new(0.01, 0),
				PaddingRight = UDim.new(0.01, 0),
			}),

			BoardContent = e("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			}, rows),
		}),
	})
end
