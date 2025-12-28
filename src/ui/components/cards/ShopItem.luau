local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)

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
	SkinContent: any?,
}

return function(props: ShopItemProps)
	local typeConfig = TYPE_COLORS[props.Type] or TYPE_COLORS.Currency
	local isRobux = props.PriceType == "Robux"
	local isCurrency = props.Type == "Currency"

	return e("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Position = props.Position,
		Size = UDim2.new(0, 140, 0.92, 0), -- Fixed pixel width, scale height
		LayoutOrder = props.LayoutOrder,
		ZIndex = 0,
	}, {
		uICorner = e("UICorner", {
			CornerRadius = UDim.new(0.05, 0),
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

		-- Category/Bonus label at top
		categoryLabel = e("TextLabel", {
			Size = UDim2.fromScale(0.9, 0.1),
			Position = UDim2.fromScale(0.5, 0.08),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Text = props.Category or "",
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			ZIndex = 5,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold, Enum.FontStyle.Italic),
		}, {
			UIStroke = e("UIStroke", {
				Color = typeConfig.stroke,
				Thickness = 1.5,
			}),
		}),

		-- Name label (coin amount for currency)
		nameLabel = e("TextLabel", {
			Size = UDim2.fromScale(0.9, 0.12),
			Position = UDim2.fromScale(0.5, 0.72),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Text = props.Name,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			ZIndex = 5,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Normal),
		}, {
			UIStroke = e("UIStroke", {
				Color = typeConfig.stroke,
				Thickness = 2,
			}),
		}),

		-- Purchase button at bottom
		purchaseButton = e(TextButton, {
			Text = (if isRobux then "R$ " else "") .. props.Price,
			Variant = "primary",
			Size = UDim2.fromScale(0.85, 0.1),
			Position = UDim2.fromScale(0.5, 0.92),
			AnchorPoint = Vector2.new(0.5, 0.5),
			CornerRadius = UDim.new(0.3, 0),
			OnClick = props.OnPurchase or function() end,
		}),

		-- Icon for currency items (coin stack visual) - centered
		icon = isCurrency and e("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = props.Icon or "rbxassetid://6034684930",
			Position = UDim2.fromScale(0.5, 0.4),
			Size = UDim2.fromScale(0.5, 0.35),
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 3,
		}) or nil,

		-- Skin preview for non-currency items - centered
		skin = not isCurrency
				and e("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.4),
					Size = UDim2.fromScale(0.7, 0.4),
					ZIndex = 0,
				}, {
					-- Centered wrapper for LetterTile
					CenterWrapper = e("Frame", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(1, 1),
					}, props.SkinContent),
				})
			or nil,
	})
end
