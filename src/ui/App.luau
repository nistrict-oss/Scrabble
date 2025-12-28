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
local LoadingScreen = require(ReplicatedStorage.UI.screens.LoadingScreen)
local TransitionFrameModule = require(ReplicatedStorage.UI.components.frames.TransitionFrame)
local TransitionFrame = TransitionFrameModule.TransitionFrame
local DailyRewardsScreen = require(ReplicatedStorage.UI.screens.DailyRewards)
local GameBackground = require(ReplicatedStorage.UI.components.frames.GameBackground)
local NotificationProvider = require(ReplicatedStorage.UI.components.notifications.NotificationProvider)
local NotificationContainer = require(ReplicatedStorage.UI.components.notifications.NotificationContainer)

-- Services
local DailyRewardsService = require(ReplicatedStorage.Shared.Services.DailyRewardsService.DailyRewardsServiceClient)

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

local ScoreContext = require(ReplicatedStorage.UI.contexts.ScoreContext)
local ScoreEffectManager = require(ReplicatedStorage.UI.components.game.ScoreEffectManager)

-- Inner app that uses Scrabble context
local function AppContent()
	local scrabbleState = useScrabbleState()

	local activeTab, setActiveTab = React.useState("Servers")
	local isLoading, setIsLoading = React.useState(true)
	local showDailyRewards, setShowDailyRewards = React.useState(false)

	local lobby = scrabbleState.lobby
	local game = scrabbleState.game

	-- Track tab history for sliding direction
	local slideDirection, setSlideDirection = React.useState("Right")

	local onTabChange = React.useCallback(function(newTab)
		if newTab == activeTab then
			return
		end

		local prevIndex = getTabIndex(activeTab)
		local currIndex = getTabIndex(newTab)

		setSlideDirection(if currIndex >= prevIndex then "Right" else "Left")
		setActiveTab(newTab)
	end, { activeTab })

	-- Main Routing
	local routingKey = "Home"
	local currentWeight = 1
	if isLoading then
		routingKey = "Loading"
		currentWeight = 0
	elseif game then
		routingKey = "Game_" .. (game.Phase or "unknown")
		currentWeight = 3
	elseif lobby then
		routingKey = "Lobby"
		currentWeight = 2
	end

	-- Track navigation depth for forward/backward swipes
	local lastWeight = React.useRef(currentWeight)
	local navDirection, setNavDirection = React.useState("Right")

	React.useEffect(function()
		if currentWeight ~= lastWeight.current then
			setNavDirection(if currentWeight > lastWeight.current then "Right" else "Left")
			lastWeight.current = currentWeight
		end
	end, { currentWeight })

	-- Prepare Content
	local mainContent = nil
	local isGame = string.find(routingKey, "Game")
	local isLobby = routingKey == "Lobby"
	local isLanding = routingKey == "Loading"

	if isLanding then
		mainContent = e(LoadingScreen, {
			OnFinished = function()
				-- Check for daily rewards
				task.spawn(function()
					if DailyRewardsService:shouldShowPopup() then
						setShowDailyRewards(true)
					end
				end)

				-- Lobby music is already playing, just transition to home screen
				setIsLoading(false)
			end,
		})
	elseif isGame then
		mainContent = e(GameScreen, {
			GameState = game,
			LobbyState = lobby,
			OnLeave = function() end,
		})
	elseif isLobby then
		mainContent = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			LobbyScreen = e(LobbyScreen, {
				LobbyState = lobby,
				OnLeave = function() end,
			}),
		})
	else
		-- Default: Show home screens with tab transitions
		local tabContent = nil
		if activeTab == "Servers" then
			tabContent = e(ServersScreen)
		elseif activeTab == "Shop" then
			tabContent = e(ShopScreen)
		elseif activeTab == "Customization" then
			tabContent = e(CustomizationScreen)
		elseif activeTab == "Leaderboards" then
			tabContent = e(LeaderboardsScreen)
		elseif activeTab == "Settings" then
			tabContent = e(SettingsScreen)
		end

		mainContent = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {

			TopBar = e(TopBar, {
				ActiveTab = activeTab,
				OnTabChange = onTabChange,
				ZIndex = 11,
			}),

			TabTransition = e(TransitionFrame, {
				TransitionKey = activeTab,
				Duration = 0.6,
				Type = "Slide",
				Direction = slideDirection,
				ZIndex = 10,
			}, tabContent),
		})
	end

	-- Global Score Effect Manager
	local scoreManagerRef = React.useRef(nil)

	local scoreSpawn = React.useCallback(function(...)
		if scoreManagerRef.current and game and game.Phase == "inGame" then
			scoreManagerRef.current.spawn(...)
		end
	end, { game and game.Phase })

	-- Clear effects when game ends or phase changes
	React.useEffect(function()
		local phase = game and game.Phase
		if not game or phase ~= "inGame" then
			if scoreManagerRef.current then
				scoreManagerRef.current.clear()
			end
		end
	end, { game and game.Phase })

	return e("ScreenGui", {
		Enabled = true,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {
		-- Persistent High-Level Background
		AppBackground = e(GameBackground, { ZIndex = -10 }),

		-- Content wrapped in ScoreContext
		Content = e(ScoreContext.Provider, {
			value = scoreSpawn,
		}, {
			ScreenTransition = e(TransitionFrame, {
				TransitionKey = routingKey,
				Type = "Slide",
				Direction = navDirection,
				Duration = 0.6,
			}, mainContent),
		}),

		-- Daily Rewards Overlay
		DailyRewards = e(DailyRewardsScreen, {
			Visible = showDailyRewards,
			OnClose = function()
				setShowDailyRewards(false)
			end,
		}),

		-- Score Effects ON TOP of everything
		ScoreEffects = e(ScoreEffectManager, {
			ref = scoreManagerRef,
		}),

		-- Toast Notifications ON TOP of everything
		Notifications = e(NotificationContainer),
	})
end

-- Main App wrapped with ScrabbleProvider and NotificationProvider
return function()
	return e(NotificationProvider, {}, {
		App = e(ScrabbleProvider, {}, {
			AppContent = e(AppContent),
		}),
	})
end
