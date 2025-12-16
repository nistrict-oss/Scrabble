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

-- Scrabble state management
local GameStateHook = require(ReplicatedStorage.UI.hooks.useGameState)
local ScrabbleProvider = GameStateHook.ScrabbleProvider
local useScrabbleState = GameStateHook.useScrabbleState

local e = React.createElement

-- Inner app that uses Scrabble context
local function AppContent()
	local scrabbleState = useScrabbleState()
	local activeTab, setActiveTab = React.useState("Servers")
	
	-- Determine which screen to show based on game state
	local lobby = scrabbleState.lobby
	local game = scrabbleState.game
	
	-- If we have an active game, show game screen
	if game and game.Phase == "inGame" then
		return e("ScreenGui", {
			Enabled = true,
			IgnoreGuiInset = true,
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		}, {
			GameScreen = e(GameScreen, {
				GameState = game,
				LobbyState = lobby,
				OnLeave = function()
					-- Will be handled by state update
				end,
			}),
		})
	end
	
	-- If we have game that ended, show result
	if game and game.Phase == "ended" then
		return e("ScreenGui", {
			Enabled = true,
			IgnoreGuiInset = true,
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		}, {
			GameScreen = e(GameScreen, {
				GameState = game,
				LobbyState = lobby,
				OnLeave = function()
					-- Will be handled by state update
				end,
			}),
		})
	end
	
	-- If we're in a lobby, show lobby screen
	if lobby then
		return e("ScreenGui", {
			Enabled = true,
			IgnoreGuiInset = true,
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		}, {
			MainFrame = e("Frame", {
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
					OnLeave = function()
						-- Will be handled by state update
					end,
				}),
			}),
		})
	end
	
	-- Default: Show home screens
	return e("ScreenGui", {
		Enabled = true,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {
		MainFrame = e("Frame", {
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
			
			TopBar = e(TopBar, {
				ActiveTab = activeTab,
				OnTabChange = function(tabName)
					setActiveTab(tabName)
				end,
			}),
			Servers = activeTab == "Servers" and e(ServersScreen) or nil,
			Shop = activeTab == "Shop" and e(ShopScreen) or nil,
			Customization = activeTab == "Customization" and e(CustomizationScreen) or nil,
			Leaderboards = activeTab == "Leaderboards" and e(LeaderboardsScreen) or nil,
			Settings = activeTab == "Settings" and e(SettingsScreen) or nil,
		}),
	})
end

-- Main App wrapped with ScrabbleProvider
return function()
	return e(ScrabbleProvider, {}, {
		AppContent = e(AppContent),
	})
end
