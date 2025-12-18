local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local StyledPanel = require(ReplicatedStorage.UI.components.frames.StyledPanel)
local LeaderboardEntry = require(ReplicatedStorage.UI.components.cards.LeaderboardEntry)
local TabButton = require(ReplicatedStorage.UI.components.buttons.TabButton)

local e = React.createElement

-- Helper function for tab buttons
local function createTabButtons(tab, setTab)
	return {
		winsButton = e(TabButton, {
			Text = "Wins",
			IsActive = tab == "Wins",
			Size = UDim2.fromScale(0.478125, 0.0993377),
			Position = UDim2.fromScale(0.50625, 0.0331126),
			CornerRadius = UDim.new(0.133333, 0),
			ZIndex = 2,
			OnClick = function()
				setTab("Wins")
			end,
		}),

		wordsFoundButton = e(TabButton, {
			Text = "Words Found",
			IsActive = tab == "WordsFound",
			Size = UDim2.fromScale(0.478125, 0.0993377),
			Position = UDim2.fromScale(0.015625, 0.0331126),
			CornerRadius = UDim.new(0.133333, 0),
			OnClick = function()
				setTab("WordsFound")
			end,
		}),
	}
end

-- Helper function for scrolling content frame
local function createScrollingContent(visible, entries)
	return e("ScrollingFrame", {
		Visible = visible,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.15),
		AnchorPoint = Vector2.new(0.5, 0),
		ScrollBarThickness = 0,
		Size = UDim2.fromScale(0.96, 0.82),
	}, {
		uIPadding = e("UIPadding", {
			PaddingTop = UDim.new(0.02, 0),
			PaddingBottom = UDim.new(0.02, 0),
			PaddingLeft = UDim.new(0.02, 0),
			PaddingRight = UDim.new(0.02, 0),
		}),

		layout = e("UIListLayout", {
			Padding = UDim.new(0.02, 0),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),

		children = React.createElement(React.Fragment, nil, entries),
	})
end

return function(_props)
	local tab, setTab = React.useState("Wins")

	local tabButtons = createTabButtons(tab, setTab)

	local winsEntries = {
		user1 = e(LeaderboardEntry, { Username = "Username", StatName = "Wins", Stat = 999, LayoutOrder = 1 }),
		user2 = e(LeaderboardEntry, { Username = "Username", StatName = "Wins", Stat = 850, LayoutOrder = 2 }),
		user3 = e(LeaderboardEntry, { Username = "Username", StatName = "Wins", Stat = 700, LayoutOrder = 3 }),
	}

	local wordsFoundEntries = {
		user1 = e(LeaderboardEntry, { Username = "Username", StatName = "Words", Stat = 120, LayoutOrder = 1 }),
		user2 = e(LeaderboardEntry, { Username = "Username", StatName = "Words", Stat = 110, LayoutOrder = 2 }),
		user3 = e(LeaderboardEntry, { Username = "Username", StatName = "Words", Stat = 100, LayoutOrder = 3 }),
	}

	return e(StyledPanel, {
		AspectRatio = 2.01297,
		CornerRadius = UDim.new(0.03003, 0),
		Children = {
			winsButton = tabButtons.winsButton,
			wordsFoundButton = tabButtons.wordsFoundButton,
			winsUsers = createScrollingContent(tab == "Wins", winsEntries),
			wordsFoundUsers = createScrollingContent(tab == "WordsFound", wordsFoundEntries),
		},
	})
end
