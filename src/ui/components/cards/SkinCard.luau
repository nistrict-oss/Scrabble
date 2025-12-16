local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)

local e = React.createElement

-- Rarity color configurations (matching original styling)
local RARITY_COLORS = {
	Common = {
		gradient = { Color3.fromRGB(85, 225, 10), Color3.fromRGB(70, 239, 176) },
		stroke = Color3.fromRGB(29, 168, 54),
	},
	Rare = {
		gradient = { Color3.fromRGB(2, 175, 224), Color3.fromRGB(163, 248, 255) },
		stroke = Color3.fromRGB(29, 147, 168),
	},
	Epic = {
		gradient = { Color3.fromRGB(183, 3, 225), Color3.fromRGB(118, 57, 241) },
		stroke = Color3.fromRGB(103, 29, 168),
	},
	Legendary = {
		gradient = { Color3.fromRGB(225, 133, 2), Color3.fromRGB(240, 196, 57) },
		stroke = Color3.fromRGB(168, 103, 29),
	},
}


export type SkinCardProps = {
	Name: string,
	Rarity: "Common" | "Rare" | "Epic" | "Legendary",
	IsEquipped: boolean?,
	Position: UDim2?,
	LayoutOrder: number?,
	OnEquip: (() -> ())?,
}

return function(props: SkinCardProps)
	local rarityConfig = RARITY_COLORS[props.Rarity] or RARITY_COLORS.Rare
	local isEquipped = props.IsEquipped == true

	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Position = props.Position,
		Size = UDim2.fromScale(0.259403, 0.993485),
		LayoutOrder = props.LayoutOrder,
		ZIndex = 0,
	}, {
		uICorner = e("UICorner", {
			CornerRadius = UDim.new(0.0373065, 0),
		}),

		uIGradient = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, rarityConfig.gradient[1]),
				ColorSequenceKeypoint.new(1, rarityConfig.gradient[2]),
			}),
			Rotation = 90,
		}),

		uIStroke = e("UIStroke", {
			Color = Color3.new(1, 1, 1),
			Thickness = 2,
		}),

		equipButton = e(TextButton, {
			Text = if isEquipped then "Equipped" else "Equip",
			Variant = if isEquipped then "primary" else "secondary",
			BackgroundImage = if isEquipped then "rbxassetid://82297622884522" else "rbxassetid://137311948105773",
			Size = UDim2.fromScale(0.994839, 0.131148),
			Position = UDim2.fromScale(0.5, 0.934426),
			AnchorPoint = Vector2.new(0.5, 0.5),
			CornerRadius = UDim.new(0.1875, 0),
			OnClick = props.OnEquip or function() end,
		}),

		skinName = e("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			FontFace = Font.new(
				"rbxassetid://11702779517",
				Enum.FontWeight.Heavy,
				Enum.FontStyle.Italic
			),
			Position = UDim2.fromScale(0.5, 0.0803279),
			RichText = true,
			Size = UDim2.fromScale(0.527265, 0.0721311),
			Text = props.Name,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			ZIndex = 2,
		}, {
			uIStroke = e("UIStroke", {
				Color = rarityConfig.stroke,
				Thickness = 5,
			}),

			uIAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 4.81818,
			}),

			uIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.0909091, 0),
				PaddingTop = UDim.new(0.0909091, 0),
			}),
		}),

		category = e("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			FontFace = Font.new(
				"rbxassetid://11702779517",
				Enum.FontWeight.ExtraBold,
				Enum.FontStyle.Normal
			),
			Position = UDim2.fromScale(0.50125, 0.820492),
			RichText = true,
			Size = UDim2.fromScale(0.146739, 0.047541),
			Text = props.Rarity,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			ZIndex = 3,
		}, {
			uIStroke = e("UIStroke", {
				Color = rarityConfig.stroke,
				Thickness = 5,
			}),

			uIAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 2.03448,
			}),

			uIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.0862069, 0),
				PaddingTop = UDim.new(0.0862069, 0),
			}),
		}),

		skin = e("ViewportFrame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.49875, 0.581967),
			Size = UDim2.fromScale(0.94261, 0.911475),
			ZIndex = 0,
		}),
	})
end
