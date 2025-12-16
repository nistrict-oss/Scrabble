local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)

local e = React.createElement

export type TabButtonProps = {
	Text: string,
	IsActive: boolean?,
	BackgroundImage: string?,
	Size: UDim2?,
	Position: UDim2?,
	LayoutOrder: number?,
	OnClick: (() -> ())?,
}


return function(props: TabButtonProps)
	local isActive = props.IsActive == true

	return e("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Position = props.Position,
		Size = props.Size or UDim2.fromScale(0.478125, 0.0993377),
		LayoutOrder = props.LayoutOrder,
		ZIndex = if isActive then 2 else 1,
	}, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0.133333, 0),
		}),

		UIGradient = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, if isActive then Color3.fromRGB(249, 0, 149) else Color3.fromRGB(47, 52, 88)),
				ColorSequenceKeypoint.new(0.918269, if isActive then Color3.fromRGB(249, 0, 149) else Color3.fromRGB(47, 52, 88)),
				ColorSequenceKeypoint.new(1, if isActive then Color3.fromRGB(180, 2, 109) else Color3.fromRGB(43, 46, 80)),
			}),
			Rotation = 90,
		}),

		UIStroke = e("UIStroke", {
			Color = Color3.new(1, 1, 1),
			Thickness = 2,
		}),

		Background = props.BackgroundImage and e("ImageLabel", {
			BackgroundTransparency = 1,
			Image = props.BackgroundImage,
			Position = UDim2.fromScale(-0.0130719, -0.133333),
			Size = UDim2.fromScale(1.02614, 1.26667),
			ZIndex = 0,
		}) or nil,

		Button = e(TextButton, {
			Text = props.Text,
			Size = UDim2.fromScale(1, 1),
			Variant = "ghost",
			Stroke = false,
			OnClick = props.OnClick,
		}),
	})
end

