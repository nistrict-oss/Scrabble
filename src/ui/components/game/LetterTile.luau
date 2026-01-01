--[[
	LetterTile.luau
	
	A letter tile in the player's rack. Clickable to select or drag for placement.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local TweenService = game:GetService("TweenService")
local SoundUtils = require(ReplicatedStorage.Shared.Modules.Core.SoundUtils)
local useCosmetics = require(ReplicatedStorage.UI.hooks.useCosmetics)
local ColorUtils = require(ReplicatedStorage.Shared.Modules.Core.ColorUtils)
local SettingsServiceClient = require(ReplicatedStorage.Shared.Services.SettingsService.SettingsServiceClient)

local Colors = require(ReplicatedStorage.Shared.Modules.Game.Colors)

local e = React.createElement

-- Animation color palettes for different animation types
local ANIMATION_PALETTES = {
	rainbow = nil, -- Uses HSV cycling instead
	aurora = {
		Color3.fromRGB(100, 255, 200), -- Cyan-green
		Color3.fromRGB(50, 200, 255), -- Light blue
		Color3.fromRGB(100, 150, 255), -- Purple-blue
		Color3.fromRGB(150, 100, 255), -- Purple
		Color3.fromRGB(100, 255, 200), -- Back to start
	},
	lava = {
		Color3.fromRGB(255, 100, 0), -- Orange
		Color3.fromRGB(255, 50, 0), -- Red-orange
		Color3.fromRGB(255, 0, 0), -- Red
		Color3.fromRGB(255, 150, 0), -- Yellow-orange
		Color3.fromRGB(255, 100, 0), -- Back to start
	},
	galaxy = {
		Color3.fromRGB(100, 50, 180), -- Purple
		Color3.fromRGB(180, 50, 150), -- Pink-purple
		Color3.fromRGB(50, 80, 200), -- Blue
		Color3.fromRGB(150, 50, 200), -- Violet
		Color3.fromRGB(100, 50, 180), -- Back to start
	},
	candy = {
		Color3.fromRGB(255, 180, 220), -- Light pink
		Color3.fromRGB(180, 200, 255), -- Light blue
		Color3.fromRGB(255, 200, 255), -- Light purple
		Color3.fromRGB(200, 255, 255), -- Light cyan
		Color3.fromRGB(255, 180, 220), -- Back to start
	},
	toxic = {
		Color3.fromRGB(100, 255, 0), -- Bright green
		Color3.fromRGB(180, 255, 0), -- Yellow-green
		Color3.fromRGB(255, 255, 0), -- Yellow
		Color3.fromRGB(150, 255, 50), -- Lime
		Color3.fromRGB(100, 255, 0), -- Back to start
	},
	ocean = {
		Color3.fromRGB(30, 130, 200), -- Deep blue
		Color3.fromRGB(50, 180, 200), -- Teal
		Color3.fromRGB(100, 200, 220), -- Light cyan
		Color3.fromRGB(30, 150, 180), -- Ocean teal
		Color3.fromRGB(30, 130, 200), -- Back to start
	},
	sunset = {
		Color3.fromRGB(255, 120, 180), -- Pink
		Color3.fromRGB(255, 100, 100), -- Coral
		Color3.fromRGB(255, 150, 50), -- Orange
		Color3.fromRGB(200, 100, 200), -- Purple
		Color3.fromRGB(255, 120, 180), -- Back to start
	},
	neon = {
		Color3.fromRGB(0, 255, 200), -- Neon cyan
		Color3.fromRGB(255, 50, 200), -- Neon pink
		Color3.fromRGB(100, 255, 100), -- Neon green
		Color3.fromRGB(150, 100, 255), -- Neon purple
		Color3.fromRGB(0, 255, 200), -- Back to start
	},
}

-- Helper function to lerp between colors in a palette
local ScrabbleConfig = require(ReplicatedStorage.Shared.Modules.Game.ScrabbleConfig)

local function getAnimatedColor(palette: { Color3 }, t: number): Color3
	local numColors = #palette - 1 -- Last color is same as first for smooth loop
	local scaledT = (t % 1) * numColors
	local index = math.floor(scaledT) + 1
	local fraction = scaledT - math.floor(scaledT)

	local c1 = palette[index]
	local c2 = palette[index + 1] or palette[1]

	return c1:Lerp(c2, fraction)
end

-- Letter point values - use single source of truth from ScrabbleConfig
local LETTER_VALUES = ScrabbleConfig.getLetterValues()

export type LetterTileProps = {
	Letter: string,
	Index: number,
	IsSelected: boolean?,
	IsDisabled: boolean?,
	IsDragging: boolean?, -- Hide tile while being dragged
	IsNew: boolean?, -- Unused, animation handled by parent
	OnClick: ((index: number, letter: string) -> ())?,
	OnDragStart: ((index: number, letter: string) -> ())?,
	OverrideColor: Color3?,
	OverrideTextColor: Color3?,
	OverrideStrokeColor: Color3?,
	ColorId: string?,
	TextColorId: string?,
	StrokeColorId: string?,
	NoPop: boolean?,
	Active: boolean?,
}

return function(props: LetterTileProps)
	local frameRef = React.useRef(nil)

	local letter = props.Letter
	local isSelected = props.IsSelected
	local isDisabled = props.IsDisabled
	local isDragging = props.IsDragging
	local noPop = if props.NoPop ~= nil then props.NoPop else true

	local cosmetics = useCosmetics()

	-- Helper to get animation type for a color ID
	local function getAnimationType(colorId: string?): string?
		if not colorId then
			return nil
		end
		local colorData = Colors.getColor(colorId)
		if colorData and colorData.IsAnimated then
			return colorData.AnimationType
		end
		return nil
	end

	-- Helper to get texture type for a color ID (for legendary solids)
	local function getTextureType(colorId: string?): string?
		if not colorId then
			return nil
		end
		local colorData = Colors.getColor(colorId)
		if colorData and colorData.Texture then
			return colorData.Texture
		end
		return nil
	end

	-- Get color IDs for each slot
	local tileId = props.ColorId or (if props.OverrideColor then nil else cosmetics.Equipped.Tile)
	local textColorId = props.TextColorId or (if props.OverrideTextColor then nil else cosmetics.Equipped.Text)
	local strokeId = props.StrokeColorId or (if props.OverrideStrokeColor then nil else cosmetics.Equipped.Stroke)

	-- Get animation types for each slot
	local tileAnimType = getAnimationType(tileId)
	local textAnimType = getAnimationType(textColorId)
	local strokeAnimType = getAnimationType(strokeId)

	-- Get texture type for tile (for legendary solid colors)
	local tileTextureType = getTextureType(tileId)

	-- Track separate animated colors for each slot
	local tileAnimColor, setTileAnimColor = React.useBinding(Color3.new(1, 1, 1))
	local textAnimColor, setTextAnimColor = React.useBinding(Color3.new(0, 0, 0))
	local strokeAnimColor, setStrokeAnimColor = React.useBinding(Color3.new(1, 1, 1))

	React.useEffect(function()
		-- Only run animation if at least one slot has an animated color
		if not tileAnimType and not textAnimType and not strokeAnimType then
			return
		end

		local RunService = game:GetService("RunService")
		local connection = RunService.Heartbeat:Connect(function()
			local t = os.clock()

			-- Helper to calculate color for an animation type
			local function calcAnimColor(animType: string): Color3
				if animType == "rainbow" then
					local hue = (t * 0.2) % 1
					return Color3.fromHSV(hue, 0.6, 1)
				else
					local palette = ANIMATION_PALETTES[animType]
					if palette then
						local cycleT = (t * 0.15) % 1 -- Slower, smooth cycling
						return getAnimatedColor(palette, cycleT)
					end
				end
				return Color3.new(1, 1, 1)
			end

			-- Update each animated slot
			if tileAnimType then
				setTileAnimColor(calcAnimColor(tileAnimType))
			end
			if textAnimType then
				setTextAnimColor(calcAnimColor(textAnimType))
			end
			if strokeAnimType then
				setStrokeAnimColor(calcAnimColor(strokeAnimType))
			end
		end)
		return function()
			connection:Disconnect()
		end
	end, { tileAnimType, textAnimType, strokeAnimType })

	-- Determine final colors - use animated binding if applicable, otherwise static
	local overrideColor = if tileAnimType then tileAnimColor else (props.OverrideColor or cosmetics.EquippedColors.Tile)
	local overrideTextColor = if textAnimType
		then textAnimColor
		else (props.OverrideTextColor or cosmetics.EquippedColors.Text)
	local overrideStrokeColor = if strokeAnimType
		then strokeAnimColor
		else (props.OverrideStrokeColor or cosmetics.EquippedColors.Stroke)

	local value = LETTER_VALUES[letter] or 0

	-- Bouncy spring animation function
	local function animateScale(targetScale)
		if not frameRef.current then
			return
		end

		local tweenInfo = TweenInfo.new(0.45, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 0, false, 0)

		local tween = TweenService:Create(frameRef.current, tweenInfo, {
			Size = UDim2.fromScale(targetScale, targetScale),
		})
		tween:Play()
	end

	local function handleClick()
		-- Finalization feedback on release
		-- Only play pop for board placements/board clicks
		if not noPop then
			SoundUtils.playTilePop()
		end

		if props.OnClick then
			props.OnClick(props.Index, letter)
		end
	end

	local function handleInputBegan(rbx, input)
		-- Allow dragging even if isDisabled (for Planning Mode)

		local isLeftClick = input.UserInputType == Enum.UserInputType.MouseButton1
		local isTouch = input.UserInputType == Enum.UserInputType.Touch
		local isGamepad = input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonA

		if isLeftClick or isTouch or isGamepad then
			-- Immediate feedback on press
			SoundUtils.playButtonClick()

			-- Only start drag if OnDragStart is provided
			if props.OnDragStart then
				props.OnDragStart(props.Index, letter)
			end
			animateScale(0.88)
		end
	end

	local function handleMouseUp()
		animateScale(1.15)
	end

	-- React to selection state with a celebratory bounce
	React.useEffect(function()
		if isSelected then
			animateScale(1.12)
			task.wait(0.45)
			animateScale(1)
		end
	end, { isSelected })

	-- Pop sound on mount
	React.useEffect(function()
		if not noPop then
			SoundUtils.playTilePop()
		end
	end, {})

	-- If being dragged, hide completely (DragPreview handles the visual follow)
	if isDragging then
		return e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		})
	end

	-- Tile colors - use pink accent when selected to match home screen
	local tileColor = isSelected and Color3.fromRGB(255, 180, 200) or overrideColor
	local strokeColor = isSelected and Color3.fromRGB(249, 0, 149) or overrideStrokeColor
	local textColor = isSelected and Color3.fromRGB(50, 45, 35) or overrideTextColor

	-- Handle the case where textColor is a binding (animated color)
	local isAnimatedText = not isSelected and textAnimType ~= nil
	local outlineColor = if isAnimatedText then Color3.new(0, 0, 0) else ColorUtils.getContrastColor(textColor)
	return e("TextButton", {
		Size = UDim2.fromScale(1, 1),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
		Text = "",
		Active = if props.Active ~= nil then props.Active else true,
		AutoButtonColor = false,
		[React.Event.Activated] = handleClick,
		[React.Event.MouseEnter] = function()
			animateScale(1.12)
		end,
		[React.Event.MouseLeave] = function()
			animateScale(1)
		end,
		[React.Event.InputBegan] = handleInputBegan,
		[React.Event.MouseButton1Up] = handleMouseUp,
	}, {
		-- Keep aspect ratio square
		UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
			AspectRatio = 1,
		}),

		ScaleFrame = e("Frame", {
			ref = frameRef,
			Size = UDim2.fromScale(1, 1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1,
		}, {
			Content = e("Frame", {
				Size = UDim2.fromScale(0.85, 0.85),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = tileColor,
				BackgroundTransparency = if isDisabled then 0.2 else 0,
				ClipsDescendants = true,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0.12, 0),
				}),

				UIStroke = e("UIStroke", {
					Color = strokeColor,
					Thickness = 2,
				}),

				-- Subtle gradient for depth instead of shadow
				UIGradient = e("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
						ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 200, 160)),
					}),
					Rotation = 180,
				}),

				-- Texture overlay for legendary solid colors
				TextureOverlay = tileTextureType
						and e("Frame", {
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
							ZIndex = 2,
						}, {
							-- Different texture effects based on type
							TextureGradient = tileTextureType == "metallic" and e("Frame", {
								Size = UDim2.fromScale(1, 1),
								BackgroundColor3 = Color3.new(1, 1, 1),
								BackgroundTransparency = 0.85,
							}, {
								UICorner = e("UICorner", { CornerRadius = UDim.new(0.12, 0) }),
								UIGradient = e("UIGradient", {
									Color = ColorSequence.new({
										ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
										ColorSequenceKeypoint.new(0.3, Color3.new(0.9, 0.9, 0.7)),
										ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
										ColorSequenceKeypoint.new(0.7, Color3.new(0.9, 0.85, 0.7)),
										ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
									}),
									Rotation = 45,
								}),
							}) or tileTextureType == "brushed" and e("Frame", {
								Size = UDim2.fromScale(1, 1),
								BackgroundColor3 = Color3.new(0.8, 0.8, 0.85),
								BackgroundTransparency = 0.9,
							}, {
								UICorner = e("UICorner", { CornerRadius = UDim.new(0.12, 0) }),
								UIGradient = e("UIGradient", {
									Color = ColorSequence.new({
										ColorSequenceKeypoint.new(0, Color3.new(0.7, 0.7, 0.75)),
										ColorSequenceKeypoint.new(0.2, Color3.new(1, 1, 1)),
										ColorSequenceKeypoint.new(0.4, Color3.new(0.8, 0.8, 0.85)),
										ColorSequenceKeypoint.new(0.6, Color3.new(1, 1, 1)),
										ColorSequenceKeypoint.new(0.8, Color3.new(0.75, 0.75, 0.8)),
										ColorSequenceKeypoint.new(1, Color3.new(0.9, 0.9, 0.95)),
									}),
									Rotation = 90,
								}),
							}) or tileTextureType == "gem" and e("Frame", {
								Size = UDim2.fromScale(1, 1),
								BackgroundColor3 = Color3.new(1, 1, 1),
								BackgroundTransparency = 0.8,
							}, {
								UICorner = e("UICorner", { CornerRadius = UDim.new(0.12, 0) }),
								UIGradient = e("UIGradient", {
									Color = ColorSequence.new({
										ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
										ColorSequenceKeypoint.new(0.25, Color3.new(0.7, 0.7, 0.8)),
										ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
										ColorSequenceKeypoint.new(0.75, Color3.new(0.8, 0.8, 0.9)),
										ColorSequenceKeypoint.new(1, Color3.new(0.9, 0.9, 1)),
									}),
									Rotation = 135,
								}),
							}) or tileTextureType == "glass" and e("Frame", {
								Size = UDim2.fromScale(1, 1),
								BackgroundColor3 = Color3.new(0.3, 0.3, 0.35),
								BackgroundTransparency = 0.85,
							}, {
								UICorner = e("UICorner", { CornerRadius = UDim.new(0.12, 0) }),
								UIGradient = e("UIGradient", {
									Color = ColorSequence.new({
										ColorSequenceKeypoint.new(0, Color3.new(0.2, 0.2, 0.25)),
										ColorSequenceKeypoint.new(0.4, Color3.new(0.5, 0.5, 0.55)),
										ColorSequenceKeypoint.new(0.6, Color3.new(0.3, 0.3, 0.35)),
										ColorSequenceKeypoint.new(1, Color3.new(0.4, 0.4, 0.45)),
									}),
									Rotation = 60,
								}),
							}) or tileTextureType == "sparkle" and e("Frame", {
								Size = UDim2.fromScale(1, 1),
								BackgroundColor3 = Color3.new(1, 0.9, 0.95),
								BackgroundTransparency = 0.85,
							}, {
								UICorner = e("UICorner", { CornerRadius = UDim.new(0.12, 0) }),
								UIGradient = e("UIGradient", {
									Color = ColorSequence.new({
										ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
										ColorSequenceKeypoint.new(0.2, Color3.new(1, 0.8, 0.9)),
										ColorSequenceKeypoint.new(0.4, Color3.new(1, 1, 1)),
										ColorSequenceKeypoint.new(0.6, Color3.new(0.95, 0.85, 0.95)),
										ColorSequenceKeypoint.new(0.8, Color3.new(1, 1, 1)),
										ColorSequenceKeypoint.new(1, Color3.new(1, 0.9, 0.95)),
									}),
									Rotation = 30,
								}),
							}) or nil,
						})
					or nil,

				Letter = e("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = letter,
					TextColor3 = textColor,
					TextScaled = true,
					FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				}, {
					UIPadding = e("UIPadding", {
						PaddingBottom = UDim.new(0.2, 0),
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

				-- Point value in bottom right
				Value = SettingsServiceClient:getSetting("ShowTilePoints") ~= false and e("TextLabel", {
					Size = UDim2.fromScale(0.3, 0.3),
					Position = UDim2.fromScale(0.92, 0.92),
					AnchorPoint = Vector2.new(1, 1),
					BackgroundTransparency = 1,
					Text = tostring(value),
					TextColor3 = textColor,
					TextTransparency = 0.3,
					TextScaled = true,
					FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				}, {
					UIStroke = e("UIStroke", {
						Color = outlineColor,
						Thickness = 1,
						Transparency = 0.7,
					}),
				}) or nil,
			}),
		}),
	})
end
