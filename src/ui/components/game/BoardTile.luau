--[[
	BoardTile.luau
	
	Individual cell on the Scrabble board. Can display:
	- Empty (with optional special tile indicator)
	- Letter tile placed on board
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

-- Special tile types and their colors
local SPECIAL_TILES = {
	TW = { label = "3W", color = Color3.fromRGB(232, 72, 72), textColor = Color3.new(1, 1, 1) }, -- Triple Word
	DW = { label = "2W", color = Color3.fromRGB(255, 166, 201), textColor = Color3.new(1, 1, 1) }, -- Double Word
	TL = { label = "3L", color = Color3.fromRGB(72, 156, 232), textColor = Color3.new(1, 1, 1) }, -- Triple Letter
	DL = { label = "2L", color = Color3.fromRGB(166, 213, 255), textColor = Color3.fromRGB(50, 50, 50) }, -- Double Letter
	CENTER = { label = "★", color = Color3.fromRGB(255, 166, 201), textColor = Color3.new(1, 1, 1) }, -- Center star
}

-- Standard Scrabble board special tile positions (1-indexed)
local SPECIAL_POSITIONS = {
	-- Triple Word (corners and edges)
	["1,1"] = "TW", ["1,8"] = "TW", ["1,15"] = "TW",
	["8,1"] = "TW", ["8,15"] = "TW",
	["15,1"] = "TW", ["15,8"] = "TW", ["15,15"] = "TW",
	
	-- Double Word (diagonal pattern)
	["2,2"] = "DW", ["3,3"] = "DW", ["4,4"] = "DW", ["5,5"] = "DW",
	["2,14"] = "DW", ["3,13"] = "DW", ["4,12"] = "DW", ["5,11"] = "DW",
	["14,2"] = "DW", ["13,3"] = "DW", ["12,4"] = "DW", ["11,5"] = "DW",
	["14,14"] = "DW", ["13,13"] = "DW", ["12,12"] = "DW", ["11,11"] = "DW",
	
	-- Triple Letter
	["2,6"] = "TL", ["2,10"] = "TL",
	["6,2"] = "TL", ["6,6"] = "TL", ["6,10"] = "TL", ["6,14"] = "TL",
	["10,2"] = "TL", ["10,6"] = "TL", ["10,10"] = "TL", ["10,14"] = "TL",
	["14,6"] = "TL", ["14,10"] = "TL",
	
	-- Double Letter
	["1,4"] = "DL", ["1,12"] = "DL",
	["3,7"] = "DL", ["3,9"] = "DL",
	["4,1"] = "DL", ["4,8"] = "DL", ["4,15"] = "DL",
	["7,3"] = "DL", ["7,7"] = "DL", ["7,9"] = "DL", ["7,13"] = "DL",
	["8,4"] = "DL", ["8,12"] = "DL",
	["9,3"] = "DL", ["9,7"] = "DL", ["9,9"] = "DL", ["9,13"] = "DL",
	["12,1"] = "DL", ["12,8"] = "DL", ["12,15"] = "DL",
	["13,7"] = "DL", ["13,9"] = "DL",
	["15,4"] = "DL", ["15,12"] = "DL",
	
	-- Center
	["8,8"] = "CENTER",
}

-- Letter point values
local LETTER_VALUES = {
	A = 1, B = 3, C = 3, D = 2, E = 1, F = 4, G = 2, H = 4,
	I = 1, J = 8, K = 5, L = 1, M = 3, N = 1, O = 1, P = 3,
	Q = 10, R = 1, S = 1, T = 1, U = 1, V = 4, W = 4, X = 8,
	Y = 4, Z = 10,
}

export type BoardTileProps = {
	Row: number,
	Col: number,
	Letter: string?,
	IsSelected: boolean?,
	IsPreview: boolean?, -- For showing where tile will be placed
	IsValid: boolean?, -- Whether the current word placement is valid
	IsDragHover: boolean?, -- A tile is being dragged over this cell
	OnClick: ((row: number, col: number) -> ())?,
	OnDrop: ((row: number, col: number) -> ())?,
	OnDragEnter: ((row: number, col: number) -> ())?,
	OnDragLeave: ((row: number, col: number) -> ())?,
	OnDragFromBoard: ((row: number, col: number, letter: string) -> ())?, -- Drag a placed tile back
}

return function(props: BoardTileProps)
	local row = props.Row
	local col = props.Col
	local letter = props.Letter
	local isSelected = props.IsSelected
	local isPreview = props.IsPreview
	local isValid = props.IsValid
	local isDragHover = props.IsDragHover
	
	local posKey = row .. "," .. col
	local specialType = SPECIAL_POSITIONS[posKey]
	local special = specialType and SPECIAL_TILES[specialType]
	
	-- Determine background color
	local bgColor = Color3.fromRGB(45, 65, 110) -- Default bright blue
	local textColor = Color3.fromRGB(150, 150, 150)
	local displayText = ""
	
	if letter then
		-- Has a letter placed
		bgColor = Color3.fromRGB(240, 220, 180) -- Tile color
		textColor = Color3.fromRGB(30, 30, 30)
		displayText = letter
	elseif special then
		bgColor = special.color
		textColor = special.textColor
		displayText = special.label
	end
	
	-- Preview tiles: green for valid, red for invalid
	if isPreview then
		if isValid then
			bgColor = Color3.fromRGB(100, 200, 100) -- Green = valid
		else
			bgColor = Color3.fromRGB(220, 100, 100) -- Red = invalid
		end
	end
	
	-- Highlight when a tile is being dragged over
	if isDragHover and not letter then
		bgColor = Color3.fromRGB(180, 80, 150) -- Pink/purple drop zone to match theme
	end
	
	local function handleClick()
		if props.OnClick then
			props.OnClick(row, col)
		end
	end
	
	local function handleMouseUp()
		-- Called when mouse is released over this cell (drop)
		if props.OnDrop then
			props.OnDrop(row, col)
		end
	end
	
	local function handleMouseDown()
		-- If this is a preview tile (player placed), allow dragging it back
		if isPreview and letter and props.OnDragFromBoard then
			props.OnDragFromBoard(row, col, letter)
		end
	end
	
	return e("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = bgColor,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		[React.Event.Activated] = handleClick,
		[React.Event.MouseButton1Down] = handleMouseDown,
		[React.Event.MouseButton1Up] = handleMouseUp,
		[React.Event.MouseEnter] = function()
			if props.OnDragEnter then
				props.OnDragEnter(row, col)
			end
		end,
		[React.Event.MouseLeave] = function()
			if props.OnDragLeave then
				props.OnDragLeave(row, col)
			end
		end,
	}, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0.15, 0),
		}),
		
		UIStroke = e("UIStroke", {
			Color = if isSelected then Color3.fromRGB(249, 0, 149) else Color3.fromRGB(30, 35, 60),
			Thickness = if isSelected then 3 else 1,
		}),
		
		Label = e("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = displayText,
			TextColor3 = textColor,
			TextScaled = true,
			FontFace = Font.new(
				"rbxassetid://11702779517",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
		}, {
			UIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.1, 0),
				PaddingTop = UDim.new(0.1, 0),
				PaddingLeft = UDim.new(0.1, 0),
				PaddingRight = UDim.new(0.1, 0),
			}),
		}),
		
		-- Letter value indicator (bottom right)
		LetterValue = letter and e("TextLabel", {
			Size = UDim2.fromScale(0.35, 0.35),
			Position = UDim2.fromScale(0.95, 0.95),
			AnchorPoint = Vector2.new(1, 1),
			BackgroundTransparency = 1,
			Text = tostring(LETTER_VALUES[letter] or 0),
			TextColor3 = Color3.fromRGB(80, 80, 80),
			TextScaled = true,
			FontFace = Font.new(
				"rbxassetid://11702779517",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
		}) or nil,
	})
end

