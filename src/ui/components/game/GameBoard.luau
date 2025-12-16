--[[
	GameBoard.luau
	
	The 15x15 Scrabble board grid. Renders all tiles and handles placement.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local BoardTile = require(ReplicatedStorage.UI.components.game.BoardTile)

local e = React.createElement

local BOARD_SIZE = 15

export type GameBoardProps = {
	Board: { { string? } }, -- 15x15 grid of letters (nil = empty)
	SelectedCell: { row: number, col: number }?,
	PreviewCells: { { row: number, col: number } }?,
	IsWordValid: boolean?, -- Whether current placement forms a valid word
	DragHoverCell: { row: number, col: number }?, -- Cell being hovered during drag
	OnCellClick: ((row: number, col: number) -> ())?,
	OnCellDrop: ((row: number, col: number) -> ())?,
	OnCellDragEnter: ((row: number, col: number) -> ())?,
	OnCellDragLeave: ((row: number, col: number) -> ())?,
	OnDragFromBoard: ((row: number, col: number, letter: string) -> ())?,
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
	
	-- Create rows
	local rows = {}
	for row = 1, BOARD_SIZE do
		local cells = {}
		for col = 1, BOARD_SIZE do
			local letter = board[row] and board[row][col]
			local isSelected = selectedCell and selectedCell.row == row and selectedCell.col == col
			local isPreview = previewLookup[row .. "," .. col]
			local isDragHover = dragHoverCell and dragHoverCell.row == row and dragHoverCell.col == col
			
			cells["Cell_" .. col] = e("Frame", {
				Size = UDim2.fromScale(1 / BOARD_SIZE, 1),
				BackgroundTransparency = 1,
				LayoutOrder = col,
			}, {
				Tile = e(BoardTile, {
					Row = row,
					Col = col,
					Letter = letter,
					IsSelected = isSelected,
					IsPreview = isPreview,
					IsValid = isWordValid,
					IsDragHover = isDragHover,
					OnClick = props.OnCellClick,
					OnDrop = props.OnCellDrop,
					OnDragEnter = props.OnCellDragEnter,
					OnDragLeave = props.OnCellDragLeave,
					OnDragFromBoard = props.OnDragFromBoard,
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
			BackgroundColor3 = Color3.fromRGB(30, 45, 90),
			ClipsDescendants = true,
		}, {
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

