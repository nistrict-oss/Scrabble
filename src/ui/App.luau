--[[
	App.luau
	
	Main application component. Handles routing between:
	- Home screens (Servers, Shop, Customization, Leaderboards, Settings)
	- Lobby waiting room
	- Game screen
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

-- Home screen components
local TopBar = require(ReplicatedStorage.UI.components.frames.HomeScreen.Header)
local ServersScreen = require(ReplicatedStorage.UI.screens.HomeScreen.Servers)
local ShopScreen = require(ReplicatedStorage.UI.screens.HomeScreen.Shop)
local CustomizationScreen = require(ReplicatedStorage.UI.screens.HomeScreen.Customization)
local LeaderboardsScreen = require(ReplicatedStorage.UI.screens.HomeScreen.Leaderboards)
local SettingsScreen = require(ReplicatedStorage.UI.screens.HomeScreen.Settings)

-- Game screen components
local LobbyScreen = require(ReplicatedStorage.UI.screens.GameScreen.Lobby)
local GameScreen = require(ReplicatedStorage.UI.screens.GameScreen.Game)
local TransitionFrame = require(ReplicatedStorage.UI.components.frames.TransitionFrame)

-- Scrabble state management
local GameStateHook = require(ReplicatedStorage.UI.hooks.useGameState)
local ScrabbleProvider = GameStateHook.ScrabbleProvider
local useScrabbleState = GameStateHook.useScrabbleState

local TAB_ORDER = {
	"Servers",
	"Shop",
	"Customization",
	"Leaderboards",
	"Settings",
}

local function getTabIndex(tabName: string)
	return table.find(TAB_ORDER, tabName) or 1
end

local e = React.createElement

-- Inner app that uses Scrabble context
local function AppContent()
	local scrabbleState = useScrabbleState()
	local activeTab, setActiveTab = React.useState("Servers")
	
	local lobby = scrabbleState.lobby
	local game = scrabbleState.game

	-- Track tab history for sliding direction
	local slideDirection, setSlideDirection = React.useState("Right")

	local onTabChange = React.useCallback(function(newTab)
		if newTab == activeTab then return end
		
		local prevIndex = getTabIndex(activeTab)
		local currIndex = getTabIndex(newTab)
		
		setSlideDirection(if currIndex >= prevIndex then "Right" else "Left")
		setActiveTab(newTab)
	end, {activeTab})

	-- Main Routing
	local routingKey = "Home"
	if game then
		routingKey = "Game_" .. (game.Phase or "unknown")
	elseif lobby then
		routingKey = "Lobby"
	end

	-- Prepare Content
	local mainContent = nil
	local isGame = string.find(routingKey, "Game")
	local isLobby = routingKey == "Lobby"

	if isGame then
		mainContent = e(GameScreen, {
			GameState = game,
			LobbyState = lobby,
			OnLeave = function() end,
		})
	elseif isLobby then
		mainContent = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
		}, {
			UIGradient = e("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(88, 213, 245)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(37, 204, 246)),
				}),
			}),
			Background = e("ImageLabel", {
				BackgroundTransparency = 1,
				Image = "rbxassetid://78034675625122",
				Position = UDim2.fromScale(-0.147917, -0.39537),
				Size = UDim2.fromScale(1.50625, 2.24722),
				ZIndex = 0,
			}),
			LobbyScreen = e(LobbyScreen, {
				LobbyState = lobby,
				OnLeave = function() end,
			}),
		})
	else
		-- Default: Show home screens with tab transitions
		local tabContent = nil
		if activeTab == "Servers" then tabContent = e(ServersScreen)
		elseif activeTab == "Shop" then tabContent = e(ShopScreen)
		elseif activeTab == "Customization" then tabContent = e(CustomizationScreen)
		elseif activeTab == "Leaderboards" then tabContent = e(LeaderboardsScreen)
		elseif activeTab == "Settings" then tabContent = e(SettingsScreen)
		end

		local headerHeight = 0.138889
		mainContent = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			UIGradient = e("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(88, 213, 245)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(37, 204, 246)),
				}),
			}),
			Background = e("ImageLabel", {
				BackgroundTransparency = 1,
				Image = "rbxassetid://78034675625122",
				Position = UDim2.fromScale(-0.147917, -0.39537),
				Size = UDim2.fromScale(1.50625, 2.24722),
				ZIndex = 0,
			}),
			
			TopBar = e(TopBar, {
				ActiveTab = activeTab,
				OnTabChange = onTabChange,
				ZIndex = 11,
			}),
			
			TabTransition = e(TransitionFrame, {
				TransitionKey = activeTab,
				Duration = 0.4,
				Type = "Slide",
				Direction = slideDirection,
				ZIndex = 10,
				Position = UDim2.fromScale(0, headerHeight),
				Size = UDim2.fromScale(1, 1 - headerHeight),
			}, tabContent),
		})
	end

	return e("ScreenGui", {
		Enabled = true,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {
		ScreenTransition = e(TransitionFrame, {
			TransitionKey = routingKey,
			Type = "Fade",
		}, mainContent)
	})
end

-- Main App wrapped with ScrabbleProvider
return function()
	return e(ScrabbleProvider, {}, {
		AppContent = e(AppContent),
	})
end
