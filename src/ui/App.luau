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
local TutorialScreen = require(ReplicatedStorage.UI.screens.GameScreen.TutorialScreen)
local LoadingScreen = require(ReplicatedStorage.UI.screens.LoadingScreen)
local TransitionFrameModule = require(ReplicatedStorage.UI.components.frames.TransitionFrame)
local TransitionFrame = TransitionFrameModule.TransitionFrame
local DailyRewardsScreen = require(ReplicatedStorage.UI.screens.DailyRewards)
local GameBackground = require(ReplicatedStorage.UI.components.frames.GameBackground)
local NotificationProvider = require(ReplicatedStorage.UI.components.notifications.NotificationProvider)
local NotificationContainer = require(ReplicatedStorage.UI.components.notifications.NotificationContainer)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)

-- Services
local DailyRewardsService = require(ReplicatedStorage.Shared.Services.DailyRewardsService.DailyRewardsServiceClient)
local SettingsService = require(ReplicatedStorage.Shared.Services.SettingsService.SettingsServiceClient)

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

	-- Tutorial state (shown once when first seeing lobbies, after daily rewards)
	local showingTutorial, setShowingTutorial = React.useState(false)
	local showTutorialPrompt, setShowTutorialPrompt = React.useState(false)
	local showSkipConfirm, setShowSkipConfirm = React.useState(false)
	local pendingTutorialCheck = React.useRef(false)

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

	-- Main Routing (tutorial comes after loading, before home)
	local routingKey = "Home"
	local currentWeight = 1
	if isLoading then
		routingKey = "Loading"
		currentWeight = 0
	elseif showingTutorial then
		routingKey = "Tutorial"
		currentWeight = 0.5
	elseif game then
		routingKey = "Game"
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

	-- Check for tutorial prompt after daily rewards close
	React.useEffect(function()
		if pendingTutorialCheck.current and not showDailyRewards then
			pendingTutorialCheck.current = false
			-- Show tutorial prompt
			if not SettingsService:isTutorialCompleted() then
				setShowTutorialPrompt(true)
			end
		end
	end, { showDailyRewards })

	-- Prepare Content
	local mainContent = nil
	local isGame = routingKey == "Game"
	local isTutorial = routingKey == "Tutorial"
	local isLobby = routingKey == "Lobby"
	local isLanding = routingKey == "Loading"

	if isLanding then
		mainContent = e(LoadingScreen, {
			OnFinished = function()
				-- Check for daily rewards first
				local hasDailyRewards = DailyRewardsService:shouldShowPopup()

				if hasDailyRewards then
					setShowDailyRewards(true)
					-- Mark that we need to check for tutorial after daily rewards close
					if not SettingsService:isTutorialCompleted() then
						pendingTutorialCheck.current = true
					end
				else
					-- No daily rewards, check tutorial immediately
					if not SettingsService:isTutorialCompleted() then
						setShowTutorialPrompt(true)
					end
				end

				-- Transition from loading
				setIsLoading(false)
			end,
		})
	elseif isTutorial then
		-- Show first-time tutorial (manual navigation, must view all slides)
		mainContent = e(TutorialScreen, {
			OnTutorialComplete = function()
				-- Mark tutorial as completed and hide it
				SettingsService:completeTutorial()
				setShowingTutorial(false)
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
		if scoreManagerRef.current and game and (game.Phase == "inGame" or game.Phase == "endingGame") then
			scoreManagerRef.current.spawn(...)
		end
	end, { game and game.Phase })

	-- Clear effects when game ends or phase changes
	React.useEffect(function()
		local phase = game and game.Phase
		if not game or (phase ~= "inGame" and phase ~= "endingGame") then
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

		-- Tutorial Prompt Popup (first-time player confirmation)
		TutorialPrompt = showTutorialPrompt
				and e("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 0.5,
					ZIndex = 50,
				}, {
					-- Popup Panel
					Panel = e("Frame", {
						Size = UDim2.fromScale(0.4, 0.35),
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.new(1, 1, 1),
						ZIndex = 51,
					}, {
						UICorner = e("UICorner", {
							CornerRadius = UDim.new(0.05, 0),
						}),

						UIGradient = e("UIGradient", {
							Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 45, 95)),
								ColorSequenceKeypoint.new(0.89, Color3.fromRGB(15, 30, 75)),
								ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 20, 60)),
							}),
							Rotation = 90,
						}),

						UIStroke = e("UIStroke", {
							Color = Color3.new(1, 1, 1),
							Thickness = 3,
						}),

						-- Icon (changes based on confirmation state)
						Icon = e("TextLabel", {
							Size = UDim2.fromScale(0.25, 0.25),
							Position = UDim2.fromScale(0.5, 0.08),
							AnchorPoint = Vector2.new(0.5, 0),
							BackgroundTransparency = 1,
							Text = if showSkipConfirm then "⚠️" else "📖",
							TextScaled = true,
							ZIndex = 52,
						}),

						-- Title (changes based on confirmation state)
						Title = e("TextLabel", {
							Size = UDim2.fromScale(0.9, 0.15),
							Position = UDim2.fromScale(0.5, 0.35),
							AnchorPoint = Vector2.new(0.5, 0),
							BackgroundTransparency = 1,
							Text = if showSkipConfirm then "Are you sure?" else "Welcome!",
							TextColor3 = if showSkipConfirm
								then Color3.fromRGB(255, 200, 100)
								else Color3.fromRGB(68, 210, 253),
							TextScaled = true,
							FontFace = Font.new(
								"rbxassetid://11702779517",
								Enum.FontWeight.Heavy,
								Enum.FontStyle.Italic
							),
							ZIndex = 52,
						}),

						-- Message (changes based on confirmation state)
						Message = e("TextLabel", {
							Size = UDim2.fromScale(0.85, 0.15),
							Position = UDim2.fromScale(0.5, 0.50),
							AnchorPoint = Vector2.new(0.5, 0),
							BackgroundTransparency = 1,
							Text = if showSkipConfirm
								then "Skipping the tutorial will prevent you from ever seeing it again."
								else "This seems to be your first time playing.\nWould you like a quick tutorial?",
							TextColor3 = Color3.fromRGB(220, 230, 250),
							TextScaled = true,
							TextWrapped = true,
							FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium),
							ZIndex = 52,
						}),

						-- Buttons Container
						Buttons = e("Frame", {
							Size = UDim2.fromScale(0.8, 0.18),
							Position = UDim2.fromScale(0.5, 0.75),
							AnchorPoint = Vector2.new(0.5, 0),
							BackgroundTransparency = 1,
							ZIndex = 52,
						}, {
							UIListLayout = e("UIListLayout", {
								FillDirection = Enum.FillDirection.Horizontal,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								VerticalAlignment = Enum.VerticalAlignment.Center,
								Padding = UDim.new(0.05, 0),
								SortOrder = Enum.SortOrder.LayoutOrder,
							}),

							-- Left Button (No Thanks / Skip Anyway)
							LeftButton = e("Frame", {
								Size = UDim2.fromScale(0.4, 1),
								BackgroundTransparency = 1,
								LayoutOrder = 1,
							}, {
								Button = e(TextButton, {
									Text = if showSkipConfirm then "Skip Anyway" else "No Thanks",
									Variant = "secondary",
									Size = UDim2.fromScale(1, 1),
									OnClick = function()
										if showSkipConfirm then
											-- Confirmed skip
											SettingsService:completeTutorial()
											setShowTutorialPrompt(false)
											setShowSkipConfirm(false)
										else
											-- Show confirmation
											setShowSkipConfirm(true)
										end
									end,
								}),
							}),

							-- Right Button (Yes Please / Go Back)
							RightButton = e("Frame", {
								Size = UDim2.fromScale(0.4, 1),
								BackgroundTransparency = 1,
								LayoutOrder = 2,
							}, {
								Button = e(TextButton, {
									Text = if showSkipConfirm then "Go Back" else "Yes, Please!",
									Variant = "primary",
									Size = UDim2.fromScale(1, 1),
									OnClick = function()
										if showSkipConfirm then
											-- Go back to first prompt
											setShowSkipConfirm(false)
										else
											-- Start tutorial
											setShowTutorialPrompt(false)
											setShowingTutorial(true)
										end
									end,
								}),
							}),
						}),
					}),
				})
			or nil,

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
