local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local StyledPanel = require(ReplicatedStorage.UI.components.frames.StyledPanel)
local LeaderboardEntry = require(ReplicatedStorage.UI.components.cards.LeaderboardEntry)
local TabButton = require(ReplicatedStorage.UI.components.buttons.TabButton)
local useLeaderboards = require(ReplicatedStorage.UI.hooks.useLeaderboards)

local e = React.createElement

-- Helper function for tab buttons
local function createTabButtons(tab, setTab)
	return {
		winsButton = e(TabButton, {
			Text = "Wins",
			IsActive = tab == "Wins",
			Size = UDim2.fromScale(0.31, 0.099),
			Position = UDim2.fromScale(0.015, 0.033),
			CornerRadius = UDim.new(0.133, 0),
			OnClick = function()
				setTab("Wins")
			end,
		}),

		wordsButton = e(TabButton, {
			Text = "Words",
			IsActive = tab == "Words",
			Size = UDim2.fromScale(0.31, 0.099),
			Position = UDim2.fromScale(0.345, 0.033),
			CornerRadius = UDim.new(0.133, 0),
			OnClick = function()
				setTab("Words")
			end,
		}),

		pointsButton = e(TabButton, {
			Text = "Points",
			IsActive = tab == "Points",
			Size = UDim2.fromScale(0.31, 0.099),
			Position = UDim2.fromScale(0.675, 0.033),
			CornerRadius = UDim.new(0.133, 0),
			OnClick = function()
				setTab("Points")
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
	local leaderboards = useLeaderboards()

	local tabButtons = createTabButtons(tab, setTab)

	local function renderEntries(data, statName)
		local elements = {}
		for i, entry in ipairs(data) do
			elements["entry_" .. i] = e(LeaderboardEntry, {
				Rank = i,
				Username = entry.DisplayName or "Player",
				UserId = entry.UserId,
				StatName = statName,
				Stat = entry.Value or 0,
				LayoutOrder = i,
			})
		end
		return elements
	end

	return e(StyledPanel, {
		AspectRatio = 2.01297,
		CornerRadius = UDim.new(0.03003, 0),
		Children = {
			winsButton = tabButtons.winsButton,
			wordsButton = tabButtons.wordsButton,
			pointsButton = tabButtons.pointsButton,

			winsUsers = createScrollingContent(tab == "Wins", renderEntries(leaderboards.Wins, "Wins")),
			wordsUsers = createScrollingContent(tab == "Words", renderEntries(leaderboards.Words, "Words")),
			pointsUsers = createScrollingContent(tab == "Points", renderEntries(leaderboards.Points, "Points")),
		},
	})
end
