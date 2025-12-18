--[[
	TabButton.luau

	A reusable tab button component for in-frame tab switching.
	Uses TextButton with primary/secondary variants based on active state.
	
	Usage:
		e(TabButton, {
			Text = "Tab Name",
			IsActive = currentTab == "TabName",
			OnClick = function() setTab("TabName") end,
		})
]]

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
	CornerRadius: UDim?,
	LayoutOrder: number?,
	ZIndex: number?,
	OnClick: (() -> ())?,
}

return function(props: TabButtonProps)
	local isActive = props.IsActive == true

	return e(TextButton, {
		Text = props.Text,
		Variant = isActive and "primary" or "secondary",
		BackgroundImage = props.BackgroundImage or "rbxassetid://130347638303988",
		Size = props.Size or UDim2.fromScale(0.489691, 0.108108),
		Position = props.Position,
		CornerRadius = props.CornerRadius or UDim.new(0.16, 0),
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
		OnClick = props.OnClick,
	})
end
