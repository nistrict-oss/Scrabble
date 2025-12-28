local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local StyledPanel = require(ReplicatedStorage.UI.components.frames.StyledPanel)
local SettingToggle = require(ReplicatedStorage.UI.components.settings.SettingToggle)
local SettingSlider = require(ReplicatedStorage.UI.components.settings.SettingSlider)
local SettingsServiceClient = require(ReplicatedStorage.Shared.Services.SettingsService.SettingsServiceClient)

local e = React.createElement

return function(_props)
	local settings, setSettings = React.useState(SettingsServiceClient:getSettings())

	React.useEffect(function()
		local updatedConn = SettingsServiceClient.OnSettingUpdated:Connect(function()
			setSettings(SettingsServiceClient:getSettings())
		end)
		local loadedConn = SettingsServiceClient.OnSettingsLoaded:Connect(function()
			setSettings(SettingsServiceClient:getSettings())
		end)
		return function()
			updatedConn:Disconnect()
			loadedConn:Disconnect()
		end
	end, { setSettings })

	local function updateSetting(name, value)
		SettingsServiceClient:updateSetting(name, value)
	end
	return e(StyledPanel, {
		AspectRatio = 2.11921,
		Children = {
			header = React.createElement("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				Position = UDim2.fromScale(0.015625, 0.0331126),
				Size = UDim2.fromScale(0.96875, 0.0993377),
			}, {
				uICorner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0.133333, 0),
				}),

				uIGradient = React.createElement("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(47, 52, 88)),
						ColorSequenceKeypoint.new(0.89, Color3.fromRGB(47, 52, 88)),
						ColorSequenceKeypoint.new(0.91, Color3.fromRGB(43, 46, 80)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(43, 46, 80)),
					}),
					Rotation = 90,
				}),

				uIStroke = React.createElement("UIStroke", {
					Color = Color3.new(1, 1, 1),
					Thickness = 2,
				}),

				background = React.createElement("ImageLabel", {
					BackgroundTransparency = 1,
					Image = "rbxassetid://122879724941312",
					Position = UDim2.fromScale(-0.00645161, -0.133333),
					Size = UDim2.fromScale(1.0129, 1.26667),
					ZIndex = 0,
				}),

				teextLabel = React.createElement("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
					RichText = true,
					Size = UDim2.fromScale(1, 1),
					Text = "Settings",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
				}, {
					uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
						AspectRatio = 20.6667,
					}),

					uIPadding = React.createElement("UIPadding", {
						PaddingBottom = UDim.new(0.26, 0),
						PaddingTop = UDim.new(0.26, 0),
					}),
				}),
			}),

			settings = React.createElement("ScrollingFrame", {
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				CanvasSize = UDim2.fromScale(0.807292, 0.560185),
				Position = UDim2.fromScale(0.015625, 0.165563),
				ScrollBarThickness = 0,
				Size = UDim2.fromScale(0.96875, 0.801324),
				ZIndex = 2,
			}, {
				uIListLayout = React.createElement("UIListLayout", {
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0.0165289, 0),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),

				LobbyVolumeSlider = e(SettingSlider, {
					Name = "Lobby Volume",
					Value = settings.LobbyMusicVolume or 0.5,
					LayoutOrder = 1,
					OnChange = function(val)
						updateSetting("LobbyMusicVolume", val)
					end,
				}),

				GameVolumeSlider = e(SettingSlider, {
					Name = "Game Volume",
					Value = settings.GameMusicVolume or 0.3,
					LayoutOrder = 2,
					OnChange = function(val)
						updateSetting("GameMusicVolume", val)
					end,
				}),

				SFXVolumeSlider = e(SettingSlider, {
					Name = "SFX Volume",
					Value = settings.SFXVolume or 0.8,
					LayoutOrder = 3,
					OnChange = function(val)
						updateSetting("SFXVolume", val)
					end,
				}),

				ShowTilePointsToggle = e(SettingToggle, {
					Name = "Show Tile Points",
					Value = settings.ShowTilePoints,
					LayoutOrder = 6,
					OnChange = function(val)
						updateSetting("ShowTilePoints", val)
					end,
				}),

				ConfirmMovesToggle = e(SettingToggle, {
					Name = "Confirm Moves",
					Value = settings.ConfirmMoves,
					LayoutOrder = 7,
					OnChange = function(val)
						updateSetting("ConfirmMoves", val)
					end,
				}),

				ShowRecentHighlightToggle = e(SettingToggle, {
					Name = "Show Recent Tiles Highlight",
					Value = settings.ShowRecentHighlight == true, -- Default to false
					LayoutOrder = 8,
					OnChange = function(val)
						updateSetting("ShowRecentHighlight", val)
					end,
				}),
			}),
		},
	})
end
