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

local ScoreContext = require(ReplicatedStorage.UI.contexts.ScoreContext)
local ScoreEffectManager = require(ReplicatedStorage.UI.components.game.ScoreEffectManager)

-- Inner app that uses Scrabble context
local function AppContent()
	local scrabbleState = useScrabbleState()
	local activeTab, setActiveTab = React.useState("Servers")

	-- Global Background Animation State
	local bgHue, setBgHue = React.useBinding(0.55) -- Light Blue start
	local bgRotation, setBgRotation = React.useBinding(0)

	React.useEffect(function()
		local RunService = game:GetService("RunService")
		local connection = RunService.RenderStepped:Connect(function(dt)
			setBgHue((bgHue:getValue() + dt * 0.003) % 100)
			setBgRotation((bgRotation:getValue() + dt * 3) % 360) -- Very slow rotation
		end)
		return function()
			connection:Disconnect()
		end
	end, {})

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
	if game then
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

	if isGame then
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
				BackgroundHue = bgHue,
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
		if scoreManagerRef.current then
			scoreManagerRef.current.spawn(...)
		end
	end, {})

	return e("ScreenGui", {
		Enabled = true,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {
		-- Persistent High-Level Background
		AppBackground = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			ZIndex = -1,
		}, {
			UIGradient = e("UIGradient", {
				Rotation = bgRotation,
				Color = bgHue:map(function(h)
					local baseH = h % 1
					local baseS = 0.850
					local baseV = 1.000

					return ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHSV(baseH, baseS, baseV)),
						ColorSequenceKeypoint.new(1, Color3.fromHSV((baseH + 0.05) % 1, baseS - 0.1, baseV)),
					})
				end),
			}),
			Decoration = e("ImageLabel", {
				BackgroundTransparency = 1,
				Image = "rbxassetid://78034675625122",
				Position = UDim2.fromScale(-0.147917, -0.39537),
				Size = UDim2.fromScale(1.50625, 2.24722),
				ZIndex = 0,
				ImageColor3 = Color3.new(1, 1, 1),
				ImageTransparency = 0.8, -- Subtle
			}),
		}),

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

		-- Score Effects ON TOP of everything
		ScoreEffects = e(ScoreEffectManager, {
			ref = scoreManagerRef,
		}),
	})
end

-- Main App wrapped with ScrabbleProvider
return function()
	return e(ScrabbleProvider, {}, {
		AppContent = e(AppContent),
	})
end
