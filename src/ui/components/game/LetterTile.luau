--[[
	LetterTile.luau
	
	A letter tile in the player's rack. Clickable to select or drag for placement.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local TweenService = game:GetService("TweenService")

local e = React.createElement

-- Letter point values
local LETTER_VALUES = {
	A = 1, B = 3, C = 3, D = 2, E = 1, F = 4, G = 2, H = 4,
	I = 1, J = 8, K = 5, L = 1, M = 3, N = 1, O = 1, P = 3,
	Q = 10, R = 1, S = 1, T = 1, U = 1, V = 4, W = 4, X = 8,
	Y = 4, Z = 10,
}

export type LetterTileProps = {
	Letter: string,
	Index: number,
	IsSelected: boolean?,
	IsDisabled: boolean?,
	IsDragging: boolean?, -- Hide tile while being dragged
	IsNew: boolean?, -- Unused, animation handled by parent
	OnClick: ((index: number, letter: string) -> ())?,
	OnDragStart: ((index: number, letter: string) -> ())?,
}

return function(props: LetterTileProps)
	local frameRef = React.useRef(nil)
	
	local letter = props.Letter
	local isSelected = props.IsSelected
	local isDisabled = props.IsDisabled
	local isDragging = props.IsDragging
	local value = LETTER_VALUES[letter] or 0
	
	-- Bouncy spring animation function
	local function animateScale(targetScale)
		if isDisabled or not frameRef.current then return end
		
		local tweenInfo = TweenInfo.new(
			0.45,
			Enum.EasingStyle.Elastic,
			Enum.EasingDirection.Out,
			0,
			false,
			0
		)
		
		local tween = TweenService:Create(frameRef.current, tweenInfo, {
			Size = UDim2.fromScale(targetScale, targetScale)
		})
		tween:Play()
	end
	
	local function handleClick()
		if isDisabled then return end
		if props.OnClick then
			props.OnClick(props.Index, letter)
		end
	end
	
	local function handleMouseDown()
		if isDisabled then return end
		animateScale(0.88)
		
		-- Only start drag if OnDragStart is provided
		if props.OnDragStart then
			props.OnDragStart(props.Index, letter)
		end
	end
	
	local function handleMouseUp()
		if isDisabled then return end
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
	
	-- If being dragged, show a ghost/placeholder
	if isDragging then
		return e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 1,
			}),
			Placeholder = e("Frame", {
				Size = UDim2.fromScale(0.85, 0.85),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(45, 70, 120),
				BackgroundTransparency = 0.5,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0.15, 0),
				}),
				UIStroke = e("UIStroke", {
					Color = Color3.fromRGB(70, 100, 160),
					Thickness = 2,
					Transparency = 0.5,
				}),
			}),
		})
	end
	
	-- Tile colors - use pink accent when selected to match home screen
	local tileColor = isSelected 
		and Color3.fromRGB(255, 180, 200) -- Light pink when selected
		or Color3.fromRGB(245, 225, 180)
	local strokeColor = isSelected 
		and Color3.fromRGB(249, 0, 149) -- Pink accent when selected
		or Color3.fromRGB(200, 180, 140)
	
	return e("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		[React.Event.Activated] = handleClick,
		[React.Event.MouseEnter] = function()
			if isDisabled then return end
			animateScale(1.12)
		end,
		[React.Event.MouseLeave] = function()
			if isDisabled then return end
			animateScale(1)
		end,
		[React.Event.MouseButton1Down] = handleMouseDown,
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
				
				Letter = e("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = letter,
					TextColor3 = Color3.fromRGB(50, 45, 35),
					TextScaled = true,
					FontFace = Font.new(
						"rbxassetid://11702779517",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
				}, {
					UIPadding = e("UIPadding", {
						PaddingBottom = UDim.new(0.2, 0),
						PaddingTop = UDim.new(0.1, 0),
						PaddingLeft = UDim.new(0.1, 0),
						PaddingRight = UDim.new(0.1, 0),
					}),
				}),
				
				-- Point value in bottom right
				Value = e("TextLabel", {
					Size = UDim2.fromScale(0.3, 0.3),
					Position = UDim2.fromScale(0.92, 0.92),
					AnchorPoint = Vector2.new(1, 1),
					BackgroundTransparency = 1,
					Text = tostring(value),
					TextColor3 = Color3.fromRGB(100, 90, 70),
					TextScaled = true,
					FontFace = Font.new(
						"rbxassetid://11702779517",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
				}),
			}),
		}),
	})
end