local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)

local e = React.createElement

export type SettingToggleProps = {
	Name: string,
	Value: boolean,
	LayoutOrder: number?,
	OnChange: ((newValue: boolean) -> ())?,
	IsDisabled: boolean?,
}

return function(props: SettingToggleProps)
	local isOn = props.Value

	-- Visual feedback for disabled state could be handled by TextButton,
	-- but we might want to dim the whole row or just the buttons.
	-- TextButton generally handles IsDisabled by graying out.

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.165289),
		LayoutOrder = props.LayoutOrder,
		ZIndex = 0,
	}, {
		background = e("ImageLabel", {
			BackgroundTransparency = 1,
			Image = "rbxassetid://137904107688579",
			Size = UDim2.fromScale(1, 1),
			ZIndex = 0,
			ImageColor3 = if props.IsDisabled then Color3.fromRGB(150, 150, 150) else Color3.new(1, 1, 1),
		}),

		settingName = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
			Position = UDim2.fromScale(0.0180645, 0.28),
			RichText = true,
			Size = UDim2.fromScale(0.173548, 0.44),
			Text = props.Name,
			TextColor3 = if props.IsDisabled then Color3.fromRGB(150, 150, 150) else Color3.new(1, 1, 1),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, {
			uIAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 6.11364,
			}),

			uIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.0909091, 0),
				PaddingTop = UDim.new(0.0909091, 0),
			}),
		}),

		onButton = e(TextButton, {
			Text = "On",
			Variant = if isOn then "primary" else "secondary",
			BackgroundImage = "rbxassetid://96562961313996",
			Size = UDim2.fromScale(0.16129, 0.75),
			Position = UDim2.fromScale(0.825806, 0.12),
			CornerRadius = UDim.new(0.133333, 0),
			ZIndex = 2,
			Disabled = props.IsDisabled,
			OnClick = function()
				if props.OnChange and not props.IsDisabled then
					props.OnChange(true)
				end
			end,
		}),

		offButton = e(TextButton, {
			Text = "Off",
			Variant = if not isOn then "primary" else "secondary",
			BackgroundImage = "rbxassetid://96562961313996",
			Size = UDim2.fromScale(0.16129, 0.75),
			Position = UDim2.fromScale(0.658065, 0.12),
			CornerRadius = UDim.new(0.133333, 0),
			ZIndex = 3,
			Disabled = props.IsDisabled,
			OnClick = function()
				if props.OnChange and not props.IsDisabled then
					props.OnChange(false)
				end
			end,
		}),
	})
end
