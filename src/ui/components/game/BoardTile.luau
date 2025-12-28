--[[
	BoardTile.luau
	
	Individual cell on the Scrabble board. Can display:
	- Empty (with optional special tile indicator)
	- Letter tile placed on board
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScrabbleConfig = require(ReplicatedStorage.Shared.Modules.Game.ScrabbleConfig)
local React = require(ReplicatedStorage.Packages.React)
local SoundUtils = require(ReplicatedStorage.Shared.Modules.Core.SoundUtils)
local useCosmetics = require(ReplicatedStorage.UI.hooks.useCosmetics)
local ColorUtils = require(ReplicatedStorage.Shared.Modules.Core.ColorUtils)
local SettingsServiceClient = require(ReplicatedStorage.Shared.Services.SettingsService.SettingsServiceClient)

local e = React.createElement

-- Colors module for converting color IDs to Color3 values
local Colors = require(ReplicatedStorage.Shared.Modules.Game.Colors)

-- Special tile types and their colors
local SPECIAL_TILES = {
	TW = { label = "3W", color = Color3.fromRGB(232, 72, 72), textColor = Color3.new(1, 1, 1) }, -- Triple Word
	DW = { label = "2W", color = Color3.fromRGB(255, 166, 201), textColor = Color3.new(1, 1, 1) }, -- Double Word
	TL = { label = "3L", color = Color3.fromRGB(72, 156, 232), textColor = Color3.new(1, 1, 1) }, -- Triple Letter
	DL = { label = "2L", color = Color3.fromRGB(166, 213, 255), textColor = Color3.fromRGB(50, 50, 50) }, -- Double Letter
	CENTER = { label = "★", color = Color3.fromRGB(255, 166, 201), textColor = Color3.new(1, 1, 1) }, -- Center star
}

-- Letter point values
local LETTER_VALUES = {
	A = 1,
	B = 3,
	C = 3,
	D = 2,
	E = 1,
	F = 4,
	G = 2,
	H = 4,
	I = 1,
	J = 8,
	K = 5,
	L = 1,
	M = 3,
	N = 1,
	O = 1,
	P = 3,
	Q = 10,
	R = 1,
	S = 1,
	T = 1,
	U = 1,
	V = 4,
	W = 4,
	X = 8,
	Y = 4,
	Z = 10,
}

export type BoardTileProps = {
	Row: number,
	Col: number,
	Letter: string?,
	TileColors: { Tile: string, Text: string, Stroke: string }?, -- Owner's color IDs (global visibility)
	IsBlank: boolean?, -- Is this a blank tile (worth 0 points)?
	IsSelected: boolean?,
	IsPreview: boolean?, -- For showing where tile will be placed
	IsValid: boolean?, -- Whether the current word placement is valid
	IsDragHover: boolean?, -- A tile is being dragged over this cell
	IsRecent: boolean?, -- Was this tile placed in the most recent turn?
	OnClick: ((row: number, col: number) -> ())?,
	OnDrop: ((row: number, col: number) -> ())?,
	OnDragEnter: ((row: number, col: number) -> ())?,
	OnDragLeave: ((row: number, col: number) -> ())?,
	OnDragFromBoard: ((row: number, col: number, letter: string) -> ())?,
	OnReportPosition: (row: number, col: number, pos: Vector2) -> (),
}

return function(props: BoardTileProps)
	local row = props.Row
	local col = props.Col
	local letter = props.Letter
	local tileColors = props.TileColors -- Owner's color IDs (may be nil)
	local isBlank = props.IsBlank -- Blank tiles are worth 0 points
	local isSelected = props.IsSelected
	local isPreview = props.IsPreview
	local isValid = props.IsValid
	local isDragHover = props.IsDragHover
	local isRecent = props.IsRecent

	-- Get local player's cosmetics as fallback
	local cosmetics = useCosmetics()

	local posKey = row .. "," .. col
	local specialType = ScrabbleConfig.SPECIAL_POSITIONS[posKey]
	local special = specialType and SPECIAL_TILES[specialType]

	-- Determine colors
	local bgColor = Color3.fromRGB(45, 65, 110) -- Default board cell color
	local textColor = Color3.fromRGB(150, 150, 150)
	local strokeColor = if isSelected then Color3.fromRGB(249, 0, 149) else Color3.fromRGB(30, 35, 60)
	local displayText = ""

	if letter then
		-- Use tile owner's colors if provided, otherwise fall back to local cosmetics
		if tileColors then
			-- Convert color IDs to Color3 values
			bgColor = Colors.getColor(tileColors.Tile).Value
			textColor = Colors.getColor(tileColors.Text).Value
			strokeColor = Colors.getColor(tileColors.Stroke).Value
		else
			-- Fallback to local player's cosmetics (shouldn't happen normally)
			bgColor = cosmetics.EquippedColors.Tile
			textColor = cosmetics.EquippedColors.Text
			strokeColor = cosmetics.EquippedColors.Stroke
		end
		displayText = letter

		-- If it's selected (high priority highlight)
		if isSelected then
			bgColor = Color3.fromRGB(255, 180, 200)
			strokeColor = Color3.fromRGB(249, 0, 149)
			textColor = Color3.fromRGB(50, 45, 35)
		end
	elseif special then
		bgColor = special.color
		textColor = special.textColor
		displayText = special.label
	end

	local outlineColor = ColorUtils.getContrastColor(textColor)
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

	local function handleInputBegan(_, input)
		-- If this is a preview tile (player placed), allow dragging it back
		local isLeftClick = input.UserInputType == Enum.UserInputType.MouseButton1
		local isTouch = input.UserInputType == Enum.UserInputType.Touch
		local isGamepad = input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonA

		if (isLeftClick or isTouch or isGamepad) and isPreview and letter and props.OnDragFromBoard then
			props.OnDragFromBoard(row, col, letter)
		end
	end

	-- Animation & Position state
	local buttonRef = React.useRef(nil :: TextButton?)

	local function reportPosition()
		if buttonRef.current and props.OnReportPosition then
			props.OnReportPosition(row, col, buttonRef.current.AbsolutePosition + buttonRef.current.AbsoluteSize / 2)
		end
	end

	React.useEffect(function()
		reportPosition()
	end, { row, col })

	React.useEffect(function()
		if letter and buttonRef.current then
			local uiScale = buttonRef.current:FindFirstChild("UIScale") :: UIScale?
			if uiScale then
				if isPreview then
					-- Preview animation: Instant pop
					SoundUtils.playTilePop()
					uiScale.Scale = 1.3
					local TweenService = game:GetService("TweenService")
					TweenService
						:Create(uiScale, TweenInfo.new(0.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
							Scale = 1,
						})
						:Play()
				else
					-- Confirmed tile animation: Wave effect
					-- Ensure starts invisible
					uiScale.Scale = 0

					-- Wave calculation: Center-Out (distance from 8,8)
					-- This ensures the game start (center) is instant, and waves flow outward
					local dist = math.abs(row - 8) + math.abs(col - 8)
					local delay = dist * 0.25

					task.delay(delay, function()
						if not buttonRef.current then
							return
						end
						-- Pop in
						uiScale.Scale = 1.3
						local TweenService = game:GetService("TweenService")
						TweenService
							:Create(uiScale, TweenInfo.new(0.7, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
								Scale = 1,
							})
							:Play()
					end)
				end
			end
		end
	end, { letter, isPreview })

	return e("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = bgColor,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ref = buttonRef,
		[React.Event.Activated] = handleClick,
		[React.Event.InputBegan] = handleInputBegan,
		[React.Event.MouseButton1Up] = handleMouseUp,
		[React.Change.AbsolutePosition] = reportPosition,
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
		UIScale = e("UIScale", {
			-- Start invisible for wave animation, visible otherwise
			Scale = if letter and not isPreview then 0 else 1,
		}),

		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0.12, 0), -- Match LetterTile corner
		}),

		-- Tile border stroke (always present for letter tiles on board)
		UIStroke = e("UIStroke", {
			Color = if letter then strokeColor else strokeColor,
			Thickness = if isSelected then 3 elseif letter then 2 else 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border, -- Draw stroke on border, not clipped
		}),

		UIGradient = letter and e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 200, 160)),
			}),
			Rotation = 180,
		}) or nil,

		-- White/Black overlay for recent tiles to make them pop (Adaptive based on brightness)
		RecentOverlay = isRecent
				and e("Frame", {
					Size = UDim2.fromScale(1, 1),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					-- If background is light, show dark overlay. If background is dark, show light overlay.
					BackgroundColor3 = if ColorUtils.getBrightness(bgColor) > 0.5
						then Color3.new(0, 0, 0)
						else Color3.new(1, 1, 1),
					BackgroundTransparency = if ColorUtils.getBrightness(bgColor) > 0.5 then 0.65 else 0.7,
					ZIndex = 3, -- On top (above Label which is 2)
				}, {
					UICorner = e("UICorner", {
						CornerRadius = UDim.new(0.12, 0),
					}),
				})
			or nil,

		Label = e("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = displayText,
			TextColor3 = textColor,
			TextScaled = true,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			ZIndex = 2,
		}, {
			UIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.2, 0), -- Match LetterTile padding
				PaddingTop = UDim.new(0.1, 0),
				PaddingLeft = UDim.new(0.1, 0),
				PaddingRight = UDim.new(0.1, 0),
			}),

			UIStroke = e("UIStroke", {
				Color = outlineColor,
				Thickness = 1,
				Transparency = 0.5,
			}),
		}),

		-- Letter value indicator (bottom right)
		LetterValue = (letter and SettingsServiceClient:getSetting("ShowTilePoints") ~= false)
				and e("TextLabel", {
					Size = UDim2.fromScale(0.3, 0.3), -- Match LetterTile value size
					Position = UDim2.fromScale(0.92, 0.92), -- Match LetterTile position
					AnchorPoint = Vector2.new(1, 1),
					BackgroundTransparency = 1,
					Text = tostring(if isBlank == true then 0 else (LETTER_VALUES[letter] or 0)),
					TextColor3 = textColor,
					TextTransparency = 0.3, -- Match LetterTile transparency
					TextScaled = true,
					FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
					ZIndex = 3,
				}, {
					UIStroke = e("UIStroke", {
						Color = outlineColor,
						Thickness = 1,
						Transparency = 0.7,
					}),
				})
			or nil,
	})
end
