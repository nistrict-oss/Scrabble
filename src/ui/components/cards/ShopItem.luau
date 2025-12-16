local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)
local ImageButton = require(ReplicatedStorage.UI.components.buttons.ImageButton)

local e = React.createElement

-- Type color configurations (matching original styling)
local TYPE_COLORS = {
	Currency = {
		gradient = { Color3.fromRGB(2, 175, 224), Color3.fromRGB(163, 248, 255) },
		stroke = Color3.fromRGB(22, 117, 134),
	},
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


export type ShopItemProps = {
	Name: string,
	Category: string,
	Type: "Currency" | "Common" | "Rare" | "Epic" | "Legendary",
	Price: string,
	PriceType: "Robux" | "Coins"?,
	Icon: string?,
	Position: UDim2?,
	LayoutOrder: number?,
	OnPurchase: (() -> ())?,
}

return function(props: ShopItemProps)
	local typeConfig = TYPE_COLORS[props.Type] or TYPE_COLORS.Currency
	local isRobux = props.PriceType == "Robux"

	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Position = props.Position,
		Size = UDim2.fromScale(0.258732, 0.993485),
		LayoutOrder = props.LayoutOrder,
		ZIndex = 0,
	}, {
		uICorner = e("UICorner", {
			CornerRadius = UDim.new(0.037307, 0),
		}),

		uIGradient = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, typeConfig.gradient[1]),
				ColorSequenceKeypoint.new(1, typeConfig.gradient[2]),
			}),
			Rotation = 90,
		}),

		uIStroke = e("UIStroke", {
			Color = Color3.new(1, 1, 1),
			Thickness = 2,
		}),

		purchaseButton = if isRobux then
			e(TextButton, {
				Text = "R$ " .. props.Price,
				Variant = "primary",
				BackgroundImage = "rbxassetid://137484194481753",
				Size = UDim2.fromScale(0.994852, 0.131148),
				Position = UDim2.fromScale(0.5, 0.934426),
				AnchorPoint = Vector2.new(0.5, 0.5),
				CornerRadius = UDim.new(0.1875, 0),
				OnClick = props.OnPurchase or function() end,
			})
		else
			e(ImageButton, {
				Image = "rbxassetid://78588043183400",
				Size = UDim2.fromScale(0.994852, 0.131148),
				OnClick = props.OnPurchase or function() end,
			}),

		price = e("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			FontFace = Font.new(
				"rbxassetid://11702779517",
				Enum.FontWeight.Heavy,
				Enum.FontStyle.Italic
			),
			Position = UDim2.fromScale(0.5, 0.752459),
			RichText = true,
			Size = UDim2.fromScale(0.223842, 0.0721311),
			Text = props.Price,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
		}, {
			uIStroke = e("UIStroke", {
				Color = typeConfig.stroke,
				Thickness = 5,
			}),

			uIAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 2.04545,
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
			Size = UDim2.fromScale(0.176586, 0.047541),
			Text = props.Category,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			ZIndex = 2,
		}, {
			uIStroke = e("UIStroke", {
				Color = typeConfig.stroke,
				Thickness = 5,
			}),

			uIAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 2.44828,
			}),

			uIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.0862069, 0),
				PaddingTop = UDim.new(0.0862069, 0),
			}),
		}),

		icon = props.Icon and e("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = props.Icon,
			Position = UDim2.fromScale(0.5025, 0.429508),
			Size = UDim2.fromScale(0.591937, 0.239344),
			ZIndex = 3,
		}) or nil,

		skin = not props.Icon and e("ViewportFrame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.49875, 0.45),
			Size = UDim2.fromScale(0.8, 0.5),
			ZIndex = 0,
		}) or nil,
	})
end
