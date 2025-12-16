local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)
local _ImageButton = require(ReplicatedStorage.UI.components.buttons.ImageButton)
local ShopItem = require(ReplicatedStorage.UI.components.cards.ShopItem)

local e = React.createElement

return function(_props)
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

        currencyButton = e(TextButton, {
            Text = "Currency",
            Variant = "primary",
            BackgroundImage = "rbxassetid://130347638303988",
            Size = UDim2.fromScale(0.478125, 0.0993377),
            Position = UDim2.fromScale(0.015625, 0.0331126),
            CornerRadius = UDim.new(0.133333, 0),
            OnClick = function() end,
        }),

        skinsButton = e(TextButton, {
            Text = "Skins",
            Variant = "secondary",
            BackgroundImage = "rbxassetid://125676755638326",
            Size = UDim2.fromScale(0.478125, 0.0993377),
            Position = UDim2.fromScale(0.50625, 0.0331126),
            CornerRadius = UDim.new(0.133333, 0),
            ZIndex = 2,
            OnClick = function() end,
        }),

        currencyx = React.createElement("ScrollingFrame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            AutomaticCanvasSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            CanvasSize = UDim2.fromScale(0.809375, 0.568519),
            Position = UDim2.fromScale(0.5, 0.562914),
            ScrollBarThickness = 0,
            ScrollingDirection = Enum.ScrollingDirection.X,
            Size = UDim2.fromScale(0.97125, 0.813245),
            Visible = false,
            ZIndex = 3,
        }, {
            currency1 = e(ShopItem, {
                Name = "Coins",
                Category = "Coins",
                Type = "Currency",
                Price = "1000",
                PriceType = "Robux",
                Icon = "rbxassetid://71701311571631",
                Position = UDim2.fromScale(0.129032, 0.5),
                LayoutOrder = 1,
                OnPurchase = function() end,
            }),

            currency2 = e(ShopItem, {
                Name = "Coins",
                Category = "Coins",
                Type = "Currency",
                Price = "5000",
                PriceType = "Coins",
                Icon = "rbxassetid://71701311571631",
                Position = UDim2.fromScale(0.4, 0.5),
                LayoutOrder = 2,
                OnPurchase = function() end,
            }),

            currency3 = e(ShopItem, {
                Name = "Coins",
                Category = "Coins",
                Type = "Currency",
                Price = "10000",
                PriceType = "Robux",
                Icon = "rbxassetid://71701311571631",
                Position = UDim2.fromScale(0.670968, 0.5),
                LayoutOrder = 3,
                OnPurchase = function() end,
            }),

            currency4 = e(ShopItem, {
                Name = "Coins",
                Category = "Coins",
                Type = "Currency",
                Price = "50000",
                PriceType = "Coins",
                Icon = "rbxassetid://71701311571631",
                Position = UDim2.fromScale(0.941936, 0.5),
                LayoutOrder = 4,
                OnPurchase = function() end,
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

        skinsx = React.createElement("ScrollingFrame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            AutomaticCanvasSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            CanvasSize = UDim2.fromScale(0.809375, 0.568519),
            Position = UDim2.fromScale(0.5, 0.562914),
            ScrollBarThickness = 0,
            ScrollingDirection = Enum.ScrollingDirection.X,
            Size = UDim2.fromScale(0.97125, 0.813245),
            ZIndex = 3,
        }, {
            skin1 = e(ShopItem, {
                Name = "Skin",
                Category = "Rare",
                Type = "Rare",
                Price = "500",
                PriceType = "Coins",
                Position = UDim2.fromScale(0.129032, 0.5),
                LayoutOrder = 1,
                OnPurchase = function() end,
            }),

            skin2 = e(ShopItem, {
                Name = "Skin",
                Category = "Epic",
                Type = "Epic",
                Price = "1500",
                PriceType = "Coins",
                Position = UDim2.fromScale(0.4, 0.5),
                LayoutOrder = 2,
                OnPurchase = function() end,
            }),

            skin3 = e(ShopItem, {
                Name = "Skin",
                Category = "Legendary",
                Type = "Legendary",
                Price = "5000",
                PriceType = "Coins",
                Position = UDim2.fromScale(0.670968, 0.5),
                LayoutOrder = 3,
                OnPurchase = function() end,
            }),

            skin4 = e(ShopItem, {
                Name = "Skin",
                Category = "Common",
                Type = "Common",
                Price = "100",
                PriceType = "Coins",
                Position = UDim2.fromScale(0.941936, 0.5),
                LayoutOrder = 4,
                OnPurchase = function() end,
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

        uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
            AspectRatio = 2.11921,
        }),
    })
end
