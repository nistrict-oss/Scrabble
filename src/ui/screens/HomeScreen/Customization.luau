local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)
local SkinCard = require(ReplicatedStorage.UI.components.cards.SkinCard)

local e = React.createElement

return function()
	return React.createElement("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Position = UDim2.fromScale(0.0833333, 0.22037),
		Size = UDim2.fromScale(0.833333, 0.699074),
	}, {
		uICorner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0.0264901, 0),
		}),

		uIGradient = React.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 99, 174)),
				ColorSequenceKeypoint.new(0.97, Color3.fromRGB(90, 99, 174)),
				ColorSequenceKeypoint.new(0.98, Color3.fromRGB(81, 88, 156)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(81, 88, 156)),
			}),
			Rotation = 90,
			Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0),
							NumberSequenceKeypoint.new(0.97, 0),
							NumberSequenceKeypoint.new(0.98, 0),
							NumberSequenceKeypoint.new(1, 0),
			}),
		}),

		uIStroke = React.createElement("UIStroke", {
			Color = Color3.new(1, 1, 1),
			Thickness = 5,
		}),

		background = React.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = "rbxassetid://89383009044144",
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			ZIndex = 0,
		}, {
			uICorner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0.0264901, 0),
			}),
		}),

		babiesButton = e(TextButton, {
			Text = "Babies",
			Variant = "primary",
			BackgroundImage = "rbxassetid://130347638303988",
			Size = UDim2.fromScale(0.478125, 0.0993377),
			Position = UDim2.fromScale(0.015625, 0.0331126),
			CornerRadius = UDim.new(0.133333, 0),
			OnClick = function()
				-- Handle babies tab click
			end,
		}),

		parentsButton = e(TextButton, {
			Text = "Parents",
			Variant = "secondary",
			BackgroundImage = "rbxassetid://125676755638326",
			Size = UDim2.fromScale(0.478125, 0.0993377),
			Position = UDim2.fromScale(0.50625, 0.0331126),
			CornerRadius = UDim.new(0.133333, 0),
			ZIndex = 2,
			OnClick = function()
				-- Handle parents tab click
			end,
		}),

		uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
			AspectRatio = 2.11921,
		}),

		babiesx = React.createElement("ScrollingFrame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			AutomaticCanvasSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			CanvasSize = UDim2.fromScale(0.807292, 0.568519),
			Position = UDim2.fromScale(0.5, 0.566742),
			ScrollBarThickness = 0,
			ScrollingDirection = Enum.ScrollingDirection.X,
			Size = UDim2.fromScale(0.96875, 0.813245),
			Visible = false,
			ZIndex = 0,
		}, {
			skin1 = e(SkinCard, {
				Name = "Skin Name",
				Rarity = "Rare",
				IsEquipped = true,
				Position = UDim2.fromScale(0.129032, 0.5),
				LayoutOrder = 1,
				OnEquip = function() end,
			}),

			skin2 = e(SkinCard, {
				Name = "Skin Name",
				Rarity = "Rare",
				IsEquipped = false,
				Position = UDim2.fromScale(0.4, 0.5),
				LayoutOrder = 2,
				OnEquip = function() end,
			}),

			skin3 = e(SkinCard, {
				Name = "Skin Name",
				Rarity = "Epic",
				IsEquipped = false,
				Position = UDim2.fromScale(0.670968, 0.5),
				LayoutOrder = 3,
				OnEquip = function() end,
			}),

			skin4 = e(SkinCard, {
				Name = "Skin Name",
				Rarity = "Legendary",
				IsEquipped = false,
				Position = UDim2.fromScale(0.941936, 0.5),
				LayoutOrder = 4,
				OnEquip = function() end,
			}),

			uIListLayout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0.0129702, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			uIPadding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0.00259403, 0),
				PaddingRight = UDim.new(0.00259403, 0),
			}),
		}),

		parentsx = React.createElement("ScrollingFrame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			AutomaticCanvasSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			CanvasSize = UDim2.fromScale(0.807292, 0.568519),
			Position = UDim2.fromScale(0.5, 0.566742),
			ScrollBarThickness = 0,
			ScrollingDirection = Enum.ScrollingDirection.X,
			Size = UDim2.fromScale(0.96875, 0.813245),
			ZIndex = 0,
		}, {
			skin1 = e(SkinCard, {
				Name = "Skin Name",
				Rarity = "Rare",
				IsEquipped = true,
				Position = UDim2.fromScale(0.129032, 0.5),
				LayoutOrder = 1,
				OnEquip = function() end,
			}),

			skin2 = e(SkinCard, {
				Name = "Skin Name",
				Rarity = "Rare",
				IsEquipped = false,
				Position = UDim2.fromScale(0.4, 0.5),
				LayoutOrder = 2,
				OnEquip = function() end,
			}),

			skin3 = e(SkinCard, {
				Name = "Skin Name",
				Rarity = "Epic",
				IsEquipped = false,
				Position = UDim2.fromScale(0.670968, 0.5),
				LayoutOrder = 3,
				OnEquip = function() end,
			}),

			skin4 = e(SkinCard, {
				Name = "Skin Name",
				Rarity = "Legendary",
				IsEquipped = false,
				Position = UDim2.fromScale(0.941936, 0.5),
				LayoutOrder = 4,
				OnEquip = function() end,
			}),

			uIListLayout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0.0129702, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			uIPadding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0.00259403, 0),
				PaddingRight = UDim.new(0.00259403, 0),
			}),
		}),
	})
end
