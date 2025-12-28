local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local StyledPanel = require(ReplicatedStorage.UI.components.frames.StyledPanel)
local TabButton = require(ReplicatedStorage.UI.components.buttons.TabButton)
local ColorCard = require(ReplicatedStorage.UI.components.cards.SkinCard)
local useCosmetics = require(ReplicatedStorage.UI.hooks.useCosmetics)
local Colors = require(ReplicatedStorage.Shared.Modules.Game.Colors)
local LetterTile = require(ReplicatedStorage.UI.components.game.LetterTile)

local e = React.createElement

-- Helper function for tab buttons
local function createTabButtons(tab, setTab)
	return {
		tileButton = e(TabButton, {
			Text = "Tile",
			IsActive = tab == "Tile",
			Size = UDim2.fromScale(0.31, 0.099),
			Position = UDim2.fromScale(0.015, 0.033),
			CornerRadius = UDim.new(0.13, 0),
			OnClick = function()
				setTab("Tile")
			end,
		}),
		textButton = e(TabButton, {
			Text = "Text",
			IsActive = tab == "Text",
			Size = UDim2.fromScale(0.31, 0.099),
			Position = UDim2.fromScale(0.345, 0.033),
			CornerRadius = UDim.new(0.13, 0),
			OnClick = function()
				setTab("Text")
			end,
		}),
		strokeButton = e(TabButton, {
			Text = "Stroke",
			IsActive = tab == "Stroke",
			Size = UDim2.fromScale(0.31, 0.099),
			Position = UDim2.fromScale(0.675, 0.033),
			CornerRadius = UDim.new(0.13, 0),
			OnClick = function()
				setTab("Stroke")
			end,
		}),
	}
end

-- Helper function for scrolling skin content
local function createSkinScrollingContent(visible, skins)
	local children = {
		uIListLayout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 15), -- Pixel-based padding
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

	for k, v in pairs(skins) do
		children[k] = v
	end

	return React.createElement("ScrollingFrame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		CanvasSize = UDim2.fromScale(0, 0),
		Position = UDim2.fromScale(0.5, 0.566742),
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Color3.fromRGB(249, 0, 149),
		ScrollBarImageTransparency = 0.3,
		ScrollingDirection = Enum.ScrollingDirection.X,
		Size = UDim2.fromScale(0.96875, 0.813245),
		Visible = visible,
		ZIndex = 0,
		ClipsDescendants = true,
	}, children)
end

-- Legacy SKINS removed

return function()
	local tab, setTab = React.useState("Tile")
	local cosmetics = useCosmetics()

	local tabButtons = createTabButtons(tab, setTab)

	-- Alphabetical color list
	local palette = Colors.getPalette()
	local sortedIds = {}
	for id in palette do
		table.insert(sortedIds, id)
	end
	table.sort(sortedIds)

	local colorCards = {}
	for i, id in ipairs(sortedIds) do
		local colorData = palette[id]
		local isOwned = table.find(cosmetics.Owned, id) ~= nil
		local isEquipped = cosmetics.Equipped[tab] == id

		-- Only show owned colors (plus defaults if we add them)
		if isOwned then
			colorCards[id] = e(ColorCard, {
				Name = colorData.Name,
				Rarity = colorData.Rarity,
				IsEquipped = isEquipped,
				LayoutOrder = i,
				OnEquip = function()
					cosmetics.Equip(tab, id)
				end,
			}, {
				-- LetterTile preview (SkinCard's skinContainer will center it)
				Preview = e(LetterTile, {
					Letter = "A",
					Index = 1,
					-- Preview specific colors for the current tab
					OverrideColor = if tab == "Tile" then colorData.Value else nil,
					OverrideTextColor = if tab == "Text" then colorData.Value else nil,
					OverrideStrokeColor = if tab == "Stroke" then colorData.Value else nil,
					-- ID support for Chroma
					ColorId = if tab == "Tile" then id else nil,
					TextColorId = if tab == "Text" then id else nil,
					StrokeColorId = if tab == "Stroke" then id else nil,
					NoPop = true,
					OnClick = function()
						cosmetics.Equip(tab, id)
					end,
				}),
			})
		end
	end

	return e(StyledPanel, {
		AspectRatio = 2.11921,
		Children = {
			-- Left Side: Preview
			PreviewPanel = e("Frame", {
				Size = UDim2.fromScale(0.35, 0.85),
				Position = UDim2.fromScale(0.02, 0.1),
				BackgroundTransparency = 1,
			}, {
				Title = e("TextLabel", {
					Size = UDim2.fromScale(1, 0.1),
					BackgroundTransparency = 1,
					Text = "CURRENT TILE",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				}),

				TileContainer = e("Frame", {
					Size = UDim2.fromScale(0.8, 0.5),
					Position = UDim2.fromScale(0.5, 0.35),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
				}, {
					Tile = e(LetterTile, {
						Letter = "A",
						Index = 1,
						OverrideColor = cosmetics.EquippedColors.Tile,
						OverrideTextColor = cosmetics.EquippedColors.Text,
						OverrideStrokeColor = cosmetics.EquippedColors.Stroke,
						ColorId = cosmetics.Equipped.Tile,
						TextColorId = cosmetics.Equipped.Text,
						StrokeColorId = cosmetics.Equipped.Stroke,
						NoPop = true,
					}),
				}),

				Status = e("TextLabel", {
					Size = UDim2.fromScale(1, 0.1),
					Position = UDim2.fromScale(0, 0.8),
					BackgroundTransparency = 1,
					Text = "Equipped Combination",
					TextColor3 = Color3.fromRGB(150, 150, 180),
					TextScaled = true,
					FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium, Enum.FontStyle.Italic),
				}),
			}),

			-- Right Side: Content
			ContentArea = e(
				"Frame",
				{
					Size = UDim2.fromScale(0.6, 1),
					Position = UDim2.fromScale(0.38, 0),
					BackgroundTransparency = 1,
				},
				(function()
					local children = {
						scrollingContent = createSkinScrollingContent(true, colorCards),
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
