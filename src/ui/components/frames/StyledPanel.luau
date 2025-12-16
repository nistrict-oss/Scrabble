local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

export type StyledPanelProps = {
	Position: UDim2?,
	Size: UDim2?,
	BackgroundImage: string?,
	StrokeThickness: number?,
	CornerRadius: UDim?,
	ZIndex: number?,
	Children: { [string]: any }?,
}

return function(props: StyledPanelProps)
	local children = props.Children or {}
	
	-- Add base styling children
	children.UICorner = e("UICorner", {
		CornerRadius = props.CornerRadius or UDim.new(0.0264901, 0),
	})
	
	children.UIGradient = e("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 99, 174)),
			ColorSequenceKeypoint.new(0.97, Color3.fromRGB(90, 99, 174)),
			ColorSequenceKeypoint.new(0.98, Color3.fromRGB(81, 88, 156)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(81, 88, 156)),
		}),
		Rotation = 90,
	})
	
	children.UIStroke = e("UIStroke", {
		Color = Color3.new(1, 1, 1),
		Thickness = props.StrokeThickness or 5,
	})
	
	if props.BackgroundImage then
		children.Background = e("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = props.BackgroundImage,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			ZIndex = 0,
		}, {
			UICorner = e("UICorner", {
				CornerRadius = props.CornerRadius or UDim.new(0.0264901, 0),
			}),
		})
	end

	return e("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Position = props.Position or UDim2.fromScale(0.0833333, 0.22037),
		Size = props.Size or UDim2.fromScale(0.833333, 0.699074),
		ZIndex = props.ZIndex,
	}, children)
end

