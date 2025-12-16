local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

export type ImageButtonProps = {
	Image: string,
	SelectedImage: string?,
	Selected: boolean?,
	Disabled: boolean?,
	LayoutOrder: number?,
	Size: UDim2?,
	Stroke: (boolean | Color3)?,
	CornerRadius: UDim?,
	OnClick: (() -> ())?,
}

return function(props: ImageButtonProps)
	local frameRef = React.useRef(nil)

	local disabled = props.Disabled
	local selected = props.Selected
	local corner = props.CornerRadius or UDim.new(0.12, 0)
	local size = props.Size
	local stroke = props.Stroke

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

	React.useEffect(function()
		if selected then
			animateScale(1.15)
			task.wait(0.45)
			animateScale(1)
		end
	end, { selected })

	return e("ImageButton", {
		Size = size,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Active = not disabled,
		AutoButtonColor = false,
		[React.Event.Activated] = handleClick,
		[React.Event.MouseEnter] = function()
			if disabled then return end
			animateScale(1.1)
		end,
		[React.Event.MouseLeave] = function()
			if disabled then return end
			animateScale(1)
		end,
		[React.Event.MouseButton1Down] = function()
			if disabled then return end
			animateScale(0.9)
		end,
		[React.Event.MouseButton1Up] = function()
			if disabled then return end
			animateScale(1.15)
		end,
	}, {
		Content = e("Frame", {
			ref = frameRef,
			Size = UDim2.fromScale(1,1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			UICorner = e("UICorner", { CornerRadius = corner }),
			UIStroke = stroke and e("UIStroke", {
				Thickness = 2,
				Color = stroke,
				Transparency = disabled and 0.5 or 0,
			}) or nil,
			Image = e("ImageLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Image = selected and (props.SelectedImage or props.Image) or props.Image,
			}),
		}),
	})
end

