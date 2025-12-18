local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local StyledPanel = require(ReplicatedStorage.UI.components.frames.StyledPanel)
local TabButton = require(ReplicatedStorage.UI.components.buttons.TabButton)
local _ImageButton = require(ReplicatedStorage.UI.components.buttons.ImageButton)
local ShopItem = require(ReplicatedStorage.UI.components.cards.ShopItem)

local e = React.createElement

-- Helper function for tab buttons
local function createTabButtons(tab, setTab)
	return {
		currencyButton = e(TabButton, {
			Text = "Currency",
			IsActive = tab == "Currency",
			Size = UDim2.fromScale(0.478125, 0.0993377),
			Position = UDim2.fromScale(0.015625, 0.0331126),
			CornerRadius = UDim.new(0.133333, 0),
			OnClick = function()
				setTab("Currency")
			end,
		}),

		skinsButton = e(TabButton, {
			Text = "Skins",
			IsActive = tab == "Skins",
			Size = UDim2.fromScale(0.478125, 0.0993377),
			Position = UDim2.fromScale(0.50625, 0.0331126),
			CornerRadius = UDim.new(0.133333, 0),
			ZIndex = 2,
			OnClick = function()
				setTab("Skins")
			end,
		}),
	}
end

-- Helper function for scrolling shop content
local function createShopScrollingContent(visible, items)
	return React.createElement("ScrollingFrame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutomaticCanvasSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		CanvasSize = UDim2.fromScale(0.809375, 0.568519),
		Position = UDim2.fromScale(0.5, 0.562914),
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		Size = UDim2.fromScale(0.97125, 0.813245),
		Visible = visible,
		ZIndex = 3,
	}, {
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

		children = React.createElement(React.Fragment, nil, items),
	})
end

return function(_props)
	local tab, setTab = React.useState("Skins")

	local tabButtons = createTabButtons(tab, setTab)

	local currencyItems = {
		currency1 = e(ShopItem, { Name = "Coins", Category = "Coins", Type = "Currency", Price = "1000", PriceType = "Robux", Icon = "rbxassetid://71701311571631", LayoutOrder = 1, OnPurchase = function() end }),
		currency2 = e(ShopItem, { Name = "Coins", Category = "Coins", Type = "Currency", Price = "5000", PriceType = "Coins", Icon = "rbxassetid://71701311571631", LayoutOrder = 2, OnPurchase = function() end }),
		currency3 = e(ShopItem, { Name = "Coins", Category = "Coins", Type = "Currency", Price = "10000", PriceType = "Robux", Icon = "rbxassetid://71701311571631", LayoutOrder = 3, OnPurchase = function() end }),
		currency4 = e(ShopItem, { Name = "Coins", Category = "Coins", Type = "Currency", Price = "50000", PriceType = "Coins", Icon = "rbxassetid://71701311571631", LayoutOrder = 4, OnPurchase = function() end }),
	}

	local skinItems = {
		skin1 = e(ShopItem, { Name = "Skin", Category = "Rare", Type = "Rare", Price = "500", PriceType = "Coins", LayoutOrder = 1, OnPurchase = function() end }),
		skin2 = e(ShopItem, { Name = "Skin", Category = "Epic", Type = "Epic", Price = "1500", PriceType = "Coins", LayoutOrder = 2, OnPurchase = function() end }),
		skin3 = e(ShopItem, { Name = "Skin", Category = "Legendary", Type = "Legendary", Price = "5000", PriceType = "Coins", LayoutOrder = 3, OnPurchase = function() end }),
		skin4 = e(ShopItem, { Name = "Skin", Category = "Common", Type = "Common", Price = "100", PriceType = "Coins", LayoutOrder = 4, OnPurchase = function() end }),
	}

	return e(StyledPanel, {
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		AspectRatio = 2.11921,
		Children = {
			currencyButton = tabButtons.currencyButton,
			skinsButton = tabButtons.skinsButton,
			currencyx = createShopScrollingContent(tab == "Currency", currencyItems),
			skinsx = createShopScrollingContent(tab == "Skins", skinItems),
		},
	})
end
