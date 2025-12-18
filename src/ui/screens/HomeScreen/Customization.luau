local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local StyledPanel = require(ReplicatedStorage.UI.components.frames.StyledPanel)
local TabButton = require(ReplicatedStorage.UI.components.buttons.TabButton)
local SkinCard = require(ReplicatedStorage.UI.components.cards.SkinCard)

local e = React.createElement

-- Helper function for tab buttons
local function createTabButtons(tab, setTab)
	return {
		babiesButton = e(TabButton, {
			Text = "Babies",
			IsActive = tab == "Babies",
			Size = UDim2.fromScale(0.478125, 0.0993377),
			Position = UDim2.fromScale(0.015625, 0.0331126),
			CornerRadius = UDim.new(0.133333, 0),
			OnClick = function()
				setTab("Babies")
			end,
		}),

		parentsButton = e(TabButton, {
			Text = "Parents",
			IsActive = tab == "Parents",
			Size = UDim2.fromScale(0.478125, 0.0993377),
			Position = UDim2.fromScale(0.50625, 0.0331126),
			CornerRadius = UDim.new(0.133333, 0),
			ZIndex = 2,
			OnClick = function()
				setTab("Parents")
			end,
		}),
	}
end

-- Helper function for scrolling skin content
local function createSkinScrollingContent(visible, skins)
	return React.createElement("ScrollingFrame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutomaticCanvasSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		CanvasSize = UDim2.fromScale(0.807292, 0.568519),
		Position = UDim2.fromScale(0.5, 0.566742),
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		Size = UDim2.fromScale(0.96875, 0.813245),
		Visible = visible,
		ZIndex = 0,
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

		children = React.createElement(React.Fragment, nil, skins),
	})
end

-- Mock data
local SKINS = {
	Babies = {
		{ Id = "b1", Name = "Baby Blue", Rarity = "Rare" },
		{ Id = "b2", Name = "Baby Pink", Rarity = "Rare" },
		{ Id = "b3", Name = "Baby Void", Rarity = "Epic" },
		{ Id = "b4", Name = "Baby Gold", Rarity = "Legendary" },
	},
	Parents = {
		{ Id = "p1", Name = "Parent Blue", Rarity = "Rare" },
		{ Id = "p2", Name = "Parent Pink", Rarity = "Rare" },
		{ Id = "p3", Name = "Parent Void", Rarity = "Epic" },
		{ Id = "p4", Name = "Parent Gold", Rarity = "Legendary" },
	},
}

return function()
	local tab, setTab = React.useState("Parents")
	local equippedBabies, setEquippedBabies = React.useState("b1")
	local equippedParents, setEquippedParents = React.useState("p1")

	local tabButtons = createTabButtons(tab, setTab)

	-- Generate Babies Skins
	local babiesSkins = {}
	for i, skin in ipairs(SKINS.Babies) do
		babiesSkins[skin.Id] = e(SkinCard, {
			Name = skin.Name,
			Rarity = skin.Rarity,
			IsEquipped = equippedBabies == skin.Id,
			LayoutOrder = i,
			OnEquip = function()
				if equippedBabies == skin.Id then
					setEquippedBabies(nil)
				else
					setEquippedBabies(skin.Id)
				end
			end,
		})
	end

	-- Generate Parents Skins
	local parentsSkins = {}
	for i, skin in ipairs(SKINS.Parents) do
		parentsSkins[skin.Id] = e(SkinCard, {
			Name = skin.Name,
			Rarity = skin.Rarity,
			IsEquipped = equippedParents == skin.Id,
			LayoutOrder = i,
			OnEquip = function()
				if equippedParents == skin.Id then
					setEquippedParents(nil)
				else
					setEquippedParents(skin.Id)
				end
			end,
		})
	end

	return e(StyledPanel, {
		AspectRatio = 2.11921,
		Children = {
			babiesButton = tabButtons.babiesButton,
			parentsButton = tabButtons.parentsButton,
			babiesx = createSkinScrollingContent(tab == "Babies", babiesSkins),
			parentsx = createSkinScrollingContent(tab == "Parents", parentsSkins),
		},
	})
end
