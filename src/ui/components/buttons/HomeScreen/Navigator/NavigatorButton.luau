local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local ImageButton = require(ReplicatedStorage.UI.components.buttons.ImageButton)

local e = React.createElement

export type NavigatorButtonProps = {
	ImageSelected: string,
	ImageUnselected: string,
	Selected: boolean?,
	LayoutOrder: number?,
	Size: UDim2?,
	OnClick: (() -> ())?,
}

return function(props: NavigatorButtonProps)
	return e(ImageButton, {
		Image = props.ImageUnselected,
		SelectedImage = props.ImageSelected,
		Selected = props.Selected,
		LayoutOrder = props.LayoutOrder,
		Size = props.Size or UDim2.fromScale(0.12, 0.12),
		CornerRadius = UDim.new(0.15, 0),
		OnClick = props.OnClick,
		ScaleType = Enum.ScaleType.Fit,
	})
end
