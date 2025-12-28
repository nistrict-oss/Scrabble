local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local StyledPanel = require(ReplicatedStorage.UI.components.frames.StyledPanel)
local TabButton = require(ReplicatedStorage.UI.components.buttons.TabButton)
local _ImageButton = require(ReplicatedStorage.UI.components.buttons.ImageButton)
local ShopItem = require(ReplicatedStorage.UI.components.cards.ShopItem)
local useCosmetics = require(ReplicatedStorage.UI.hooks.useCosmetics)
local Colors = require(ReplicatedStorage.Shared.Modules.Game.Colors)
local LetterTile = require(ReplicatedStorage.UI.components.game.LetterTile)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)
local useNotification = require(ReplicatedStorage.UI.hooks.useNotification)
local CurrencyService = require(ReplicatedStorage.Shared.Services.CurrencyService.CurrencyServiceClient)
local PurchaseService = require(ReplicatedStorage.Shared.Services.PurchaseService.PurchaseServiceClient)

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
	local children = {
		uIListLayout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 15), -- Pixel-based padding works better with AutomaticCanvasSize
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),

		uiPadding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 15),
			PaddingRight = UDim.new(0, 15),
			PaddingTop = UDim.new(0, 5),
			PaddingBottom = UDim.new(0, 5),
		}),
	}

	for k, v in pairs(items) do
		children[k] = v
	end

	return React.createElement("ScrollingFrame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		CanvasSize = UDim2.fromScale(0, 0),
		Position = UDim2.fromScale(0.5, 0.56),
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Color3.fromRGB(249, 0, 149),
		ScrollBarImageTransparency = 0.3,
		ScrollingDirection = Enum.ScrollingDirection.X,
		Size = UDim2.fromScale(0.97125, 0.813245),
		Visible = visible,
		ZIndex = 3,
		ClipsDescendants = true, -- Ensure proper clipping
	}, children)
end

-- Helper for slot selection buttons
local function createSlotButtons(currentSlot, setSlot)
	local slots = { "Tile", "Text", "Stroke" }
	local children = {}
	for i, name in ipairs(slots) do
		children[name] = e(TabButton, {
			Text = name,
			IsActive = currentSlot == name,
			Size = UDim2.fromScale(0.3, 0.8),
			Position = UDim2.fromScale(0.025 + (i - 1) * 0.325, 0.5),
			AnchorPoint = Vector2.new(0, 0.5),
			CornerRadius = UDim.new(0.2, 0),
			OnClick = function()
				setSlot(name)
			end,
		})
	end
	return children
end

return function(_props)
	local tab, setTab = React.useState("Skins")
	local slot, setSlot = React.useState("Tile") -- Which slot we are previewing/equiping for
	local selectedColorId, setSelectedColorId = React.useState(nil)
	local cosmetics = useCosmetics()
	local notification = useNotification()

	-- Subscribe to purchase events for toast notifications
	React.useEffect(function()
		local connections = {}

		-- Success notification
		table.insert(connections, PurchaseService.OnProductPurchased:Connect(function(_productId, productName)
			local product = require(ReplicatedStorage.Shared.Modules.Game.Purchases).getProduct(productName)
			if product and product.coins then
				notification.showNotification("🪙 +" .. product.coins .. " Coins purchased!", "success")
			end
		end))

		-- Failure notification
		table.insert(connections, PurchaseService.OnPurchaseFailed:Connect(function(reason)
			notification.showNotification("Purchase failed: " .. (reason or "Unknown error"), "error")
		end))

		return function()
			for _, conn in connections do
				conn:Disconnect()
			end
		end
	end, {})

	local tabButtons = createTabButtons(tab, setTab)

	-- Generate currency items with balanced 2025 pricing
	-- Base rate: ~5 coins per Robux, with bonuses at higher tiers
	local currencyItems = {
		currency1 = e(ShopItem, {
			Name = "100 Coins",
			Category = "Starter",
			Type = "Currency",
			Price = "25",
			PriceType = "Robux",
			Icon = "rbxassetid://6034684930",
			LayoutOrder = 1,
			OnPurchase = function()
				PurchaseService:promptProduct("Coins100")
			end,
		}),
		currency2 = e(ShopItem, {
			Name = "500 Coins",
			Category = "Small",
			Type = "Currency",
			Price = "99",
			PriceType = "Robux",
			Icon = "rbxassetid://6034684930",
			LayoutOrder = 2,
			OnPurchase = function()
				PurchaseService:promptProduct("Coins500")
			end,
		}),
		currency3 = e(ShopItem, {
			Name = "1,500 Coins",
			Category = "Medium +20%",
			Type = "Currency",
			Price = "249",
			PriceType = "Robux",
			Icon = "rbxassetid://6034684930",
			LayoutOrder = 3,
			OnPurchase = function()
				PurchaseService:promptProduct("Coins1500")
			end,
		}),
		currency4 = e(ShopItem, {
			Name = "3,500 Coins",
			Category = "Large +40%",
			Type = "Currency",
			Price = "499",
			PriceType = "Robux",
			Icon = "rbxassetid://6034684930",
			LayoutOrder = 4,
			OnPurchase = function()
				PurchaseService:promptProduct("Coins3500")
			end,
		}),
		currency5 = e(ShopItem, {
			Name = "8,000 Coins",
			Category = "Mega +60%",
			Type = "Currency",
			Price = "999",
			PriceType = "Robux",
			Icon = "rbxassetid://6034684930",
			LayoutOrder = 5,
			OnPurchase = function()
				PurchaseService:promptProduct("Coins8000")
			end,
		}),
		currency6 = e(ShopItem, {
			Name = "20,000 Coins",
			Category = "Ultimate +100%",
			Type = "Currency",
			Price = "1,999",
			PriceType = "Robux",
			Icon = "rbxassetid://6034684930",
			LayoutOrder = 6,
			OnPurchase = function()
				PurchaseService:promptProduct("Coins20000")
			end,
		}),
	}

	local skinItems = {}
	local palette = Colors.getPalette()
	local sortedIds = {}
	for id in palette do
		table.insert(sortedIds, id)
	end

	-- Sort by Price (ascending)
	table.sort(sortedIds, function(a, b)
		local colorA = palette[a]
		local colorB = palette[b]
		if colorA.Price ~= colorB.Price then
			return colorA.Price < colorB.Price
		end
		return colorA.Name < colorB.Name
	end)

	for i, id in ipairs(sortedIds) do
		local colorData = palette[id]
		local isOwned = table.find(cosmetics.Owned, id) ~= nil
		local isSelected = selectedColorId == id

		skinItems[id] = e(ShopItem, {
			Name = colorData.Name,
			Category = colorData.Rarity,
			Type = colorData.Rarity,
			Price = if isOwned then "Owned" else tostring(colorData.Price),
			PriceType = if isOwned then nil else "Coins",
			LayoutOrder = i,
			OnPurchase = function()
				setSelectedColorId(id)
			end,
			SkinContent = {
				Preview = e(LetterTile, {
					Letter = "A",
					Index = i,
					OverrideColor = colorData.Value,
					ColorId = id, -- Pass ID for chroma support
					OnClick = function()
						setSelectedColorId(id)
					end,
				}),
			},
		})
	end

	-- Preview logic
	local previewColorData = selectedColorId and palette[selectedColorId]
	local isOwned = selectedColorId and table.find(cosmetics.Owned, selectedColorId) ~= nil

	local previewTileProps = {
		Letter = "A",
		Index = 1,
		-- Use equipped colors as base
		OverrideColor = cosmetics.EquippedColors.Tile,
		OverrideTextColor = cosmetics.EquippedColors.Text,
		OverrideStrokeColor = cosmetics.EquippedColors.Stroke,
		ColorId = cosmetics.Equipped.Tile,
		TextColorId = cosmetics.Equipped.Text,
		StrokeColorId = cosmetics.Equipped.Stroke,
		NoPop = true,
	}

	-- Apply selected color to the active preview slot
	if previewColorData then
		if slot == "Tile" then
			previewTileProps.OverrideColor = previewColorData.Value
			previewTileProps.ColorId = selectedColorId
		elseif slot == "Text" then
			previewTileProps.OverrideTextColor = previewColorData.Value
			previewTileProps.TextColorId = selectedColorId
		elseif slot == "Stroke" then
			previewTileProps.OverrideStrokeColor = previewColorData.Value
			previewTileProps.StrokeColorId = selectedColorId
		end
	end

	return e(StyledPanel, {
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		AspectRatio = 2.11921,
		Children = {
			-- Left Side: Preview
			PreviewPanel = tab == "Skins"
					and e("Frame", {
						Size = UDim2.fromScale(0.35, 0.85),
						Position = UDim2.fromScale(0.02, 0.1),
						BackgroundTransparency = 1,
					}, {
						Title = e("TextLabel", {
							Size = UDim2.fromScale(1, 0.1),
							Position = UDim2.fromScale(0, 0),
							BackgroundTransparency = 1,
							Text = "PREVIEW",
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							FontFace = Font.new(
								"rbxassetid://11702779517",
								Enum.FontWeight.Bold,
								Enum.FontStyle.Normal
							),
						}),

						TileContainer = e("Frame", {
							Size = UDim2.fromScale(0.8, 0.5),
							Position = UDim2.fromScale(0.5, 0.35),
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundTransparency = 1,
						}, {
							Tile = e(LetterTile, previewTileProps),
						}),

						SlotSelection = e("Frame", {
							Size = UDim2.fromScale(1, 0.15),
							Position = UDim2.fromScale(0, 0.6),
							BackgroundTransparency = 1,
						}, createSlotButtons(slot, setSlot)),

						ActionButton = previewColorData
								and e(TextButton, {
									Text = if isOwned then "Equip to " .. slot else "Buy " .. previewColorData.Name,
									Variant = "primary",
									Size = UDim2.fromScale(1, 0.15),
									Position = UDim2.fromScale(0, 0.85),
									OnClick = function()
										if isOwned then
											cosmetics.Equip(slot, selectedColorId)
											notification.showNotification(
												"Equipped " .. previewColorData.Name .. "!",
												"success"
											)
										else
											-- Check if player has enough coins
											local playerCoins = CurrencyService:getCoins()
											if playerCoins >= previewColorData.Price then
												cosmetics.Buy(selectedColorId)
												notification.showNotification(
													"Purchased " .. previewColorData.Name .. "!",
													"success"
												)
											else
												notification.showNotification("Not enough coins!", "error")
											end
										end
									end,
								})
							or nil,
					})
				or nil,

			-- Right Side: Content
			ContentArea = e(
				"Frame",
				{
					Size = if tab == "Skins" then UDim2.fromScale(0.6, 1) else UDim2.fromScale(1, 1),
					Position = if tab == "Skins" then UDim2.fromScale(0.38, 0) else UDim2.fromScale(0, 0),
					BackgroundTransparency = 1,
				},
				(function()
					local children = {
						currencyx = createShopScrollingContent(tab == "Currency", currencyItems),
						skinsx = createShopScrollingContent(tab == "Skins", skinItems),
					}
					for k, v in pairs(tabButtons) do
						children[k] = v
					end
					return children
				end)()
			),
		},
	})
end
