local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

-- Button style presets
local STYLES = {
	primary = {
		gradient = {
			ColorSequenceKeypoint.new(0, Color3.fromRGB(249, 0, 149)),
			ColorSequenceKeypoint.new(0.918269, Color3.fromRGB(249, 0, 149)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 2, 109)),
		},
	},
	secondary = {
		gradient = {
			ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 70, 120)),
			ColorSequenceKeypoint.new(0.89, Color3.fromRGB(45, 70, 120)),
			ColorSequenceKeypoint.new(0.91, Color3.fromRGB(35, 55, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 55, 100)),
		},
	},
}

export type TextButtonProps = {
	Text: string,
	Variant: "primary" | "secondary" | "ghost"?,
	BackgroundImage: string?,
	Disabled: boolean?,
	LayoutOrder: number?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	CornerRadius: UDim?,
	Stroke: boolean?,
	ZIndex: number?,
	OnClick: (() -> ())?,
}

return function(props: TextButtonProps)
	local frameRef = React.useRef(nil)

	local disabled = props.Disabled
	local variant = props.Variant or "primary"
	local corner = props.CornerRadius or UDim.new(0.1875, 0)
	local size = props.Size or UDim2.fromScale(1, 1)
	local style = STYLES[variant]

	local function handleClick()
		if disabled then return end
		if props.OnClick then
			props.OnClick()
		end
	end

	local function animateScale(targetScale)
		if disabled or not frameRef.current then return end
		
		local tweenInfo = TweenInfo.new(
			0.4, -- Duration
			Enum.EasingStyle.Elastic, -- Bouncy easing
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

	-- Ghost variant is just text, no background
	if variant == "ghost" then
		return e("TextButton", {
			Size = size,
			Position = props.Position,
			AnchorPoint = props.AnchorPoint,
			BackgroundTransparency = 1,
			LayoutOrder = props.LayoutOrder,
			Active = not disabled,
			Text = "",
			AutoButtonColor = false,
			ZIndex = props.ZIndex,
			[React.Event.Activated] = handleClick,
			[React.Event.MouseEnter] = function()
				if disabled then return end
				animateScale(1.05)
			end,
			[React.Event.MouseLeave] = function()
				if disabled then return end
				animateScale(1)
			end,
			[React.Event.MouseButton1Down] = function()
				if disabled then return end
				animateScale(0.95)
			end,
			[React.Event.MouseButton1Up] = function()
				if disabled then return end
				animateScale(1.05)
			end,
		}, {
			Content = e("Frame", {
				ref = frameRef,
				Size = UDim2.fromScale(1,1),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundTransparency = 1,
			}, {
				TextLabel = e("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = props.Text,
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					FontFace = Font.new(
						"rbxassetid://11702779517",
						Enum.FontWeight.Heavy,
						Enum.FontStyle.Italic
					),
					TextTransparency = disabled and 0.5 or 0,
				}, {
					UIPadding = e("UIPadding", {
						PaddingBottom = UDim.new(0.2, 0),
						PaddingTop = UDim.new(0.2, 0),
						PaddingLeft = UDim.new(0.05, 0),
						PaddingRight = UDim.new(0.05, 0),
					}),
				}),
			}),
		})
	end

	-- Styled button with background
	return e("TextButton", {
		Size = size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Active = not disabled,
		Text = "",
		AutoButtonColor = false,
		ZIndex = props.ZIndex,
		[React.Event.Activated] = handleClick,
		[React.Event.MouseEnter] = function()
			if disabled then return end
			animateScale(1.05)
		end,
		[React.Event.MouseLeave] = function()
			if disabled then return end
			animateScale(1)
		end,
		[React.Event.MouseButton1Down] = function()
			if disabled then return end
			animateScale(0.95)
		end,
		[React.Event.MouseButton1Up] = function()
			if disabled then return end
			animateScale(1.05)
		end,
	}, {
		Content = e("Frame", {
			ref = frameRef,
			Size = UDim2.fromScale(1,1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
		}, {
			UICorner = e("UICorner", {
				CornerRadius = corner,
			}),

			UIGradient = style and e("UIGradient", {
				Color = ColorSequence.new(style.gradient),
				Rotation = 90,
			}) or nil,

			UIStroke = props.Stroke ~= false and e("UIStroke", {
				Color = Color3.new(1, 1, 1),
				Thickness = 2,
				Transparency = disabled and 0.5 or 0,
			}) or nil,

			Background = props.BackgroundImage and e("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = props.BackgroundImage,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1.05, 1.225),
				ZIndex = 0,
			}) or nil,

			TextLabel = e("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = props.Text,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				ZIndex = 2,
				FontFace = Font.new(
					"rbxassetid://11702779517",
					Enum.FontWeight.Heavy,
					Enum.FontStyle.Italic
				),
				TextTransparency = disabled and 0.5 or 0,
			}, {
				UIPadding = e("UIPadding", {
					PaddingBottom = UDim.new(0.2, 0),
					PaddingTop = UDim.new(0.2, 0),
					PaddingLeft = UDim.new(0.05, 0),
					PaddingRight = UDim.new(0.05, 0),
				}),
			}),
		}),
	})
end
