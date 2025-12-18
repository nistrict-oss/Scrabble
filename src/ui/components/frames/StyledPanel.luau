local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local GameConstants = require(ReplicatedStorage.Shared.Modules.Core.GameConstants)

local e = React.createElement

export type StyledPanelProps = {
	Position: UDim2?,
	Size: UDim2?,
	AnchorPoint: Vector2?,
	BackgroundImage: string?,
	StrokeThickness: number?,
	CornerRadius: UDim?,
	AspectRatio: number?,
	ZIndex: number?,
	Children: { [string]: any }?,
}

return function(props: StyledPanelProps)
	local children = props.Children or {}
	local cornerRadius = props.CornerRadius or UDim.new(0.0264901, 0)
	
	-- Add base styling children
	children.UICorner = e("UICorner", {
		CornerRadius = cornerRadius,
	})
	
	children.UIGradient = e("UIGradient", {
		Color = ColorSequence.new(GameConstants.Gradients.frame),
		Rotation = 90,
	})
	
	children.UIStroke = e("UIStroke", {
		Color = Color3.new(1, 1, 1),
		Thickness = props.StrokeThickness or 5,
	})
	
	local backgroundImage = props.BackgroundImage or "rbxassetid://89383009044144"
	children.Background = e("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = backgroundImage,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		ZIndex = -1,
	}, {
		UICorner = e("UICorner", {
			CornerRadius = cornerRadius,
		}),
	})
	
	if props.AspectRatio then
		children.UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
			AspectRatio = props.AspectRatio,
		})
	end

	return e("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Position = UDim2.fromScale(0.5,0.5),
		Size = UDim2.fromScale(0.833333, 0.699074),
		AnchorPoint = Vector2.new(0.5,0.5),
		ZIndex = props.ZIndex,
	}, children)
end

