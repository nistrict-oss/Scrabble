--[[
	Servers.luau
	
	Server browser / lobby list screen. Shows available game lobbies
	and allows creating new ones.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.React)
local ServerEntry = require(ReplicatedStorage.UI.components.cards.ServerEntry)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)
local ScrabbleServiceClient = require(ReplicatedStorage.Shared.Services.ScrabbleService.ScrabbleServiceClient)
local GameStateHook = require(ReplicatedStorage.UI.hooks.useGameState)

local e = React.createElement

local useScrabbleState = GameStateHook.useScrabbleState
local LocalPlayer = Players.LocalPlayer

return function(_props)
	local scrabbleState = useScrabbleState()
	local lobbies = scrabbleState.lobbies or {}
	local showCreateModal, setShowCreateModal = React.useState(false)
	local lobbyName, setLobbyName = React.useState(LocalPlayer.Name .. "'s Game")
	local maxPlayers, setMaxPlayers = React.useState(4)
	local isPrivate, setIsPrivate = React.useState(false)
	
	-- Build lobby entries
	local entries = {}
	
	for i, lobby in ipairs(lobbies) do
		entries["Lobby_" .. i] = e(ServerEntry, {
			HostName = lobby.HostName or "Unknown",
			HostUserId = lobby.HostUserId,
			PlayerCount = lobby.Players or 0,
			MaxPlayers = lobby.MaxPlayers or 4,
			IsPrivate = lobby.Private,
			LayoutOrder = i + 1,
			OnJoin = function()
				ScrabbleServiceClient:joinLobby(lobby.Id)
			end,
			OnSpectate = function()
				-- TODO: Spectate mode
				warn("Spectate not implemented yet")
			end,
		})
	end
	
	-- Empty state
	if #lobbies == 0 then
		entries["EmptyState"] = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 100),
			BackgroundTransparency = 1,
			Text = "No games available.\nCreate one to get started!",
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			LayoutOrder = 2,
			FontFace = Font.new(
				"rbxassetid://11702779517",
				Enum.FontWeight.Medium,
				Enum.FontStyle.Italic
			),
		}, {
			UIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.2, 0),
				PaddingTop = UDim.new(0.2, 0),
			}),
		})
	end
	
	entries["UIListLayout"] = e("UIListLayout", {
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0.02, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	
	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		-- Create button at top
		CreateButtonContainer = e("Frame", {
			Size = UDim2.fromScale(0.25, 0.08),
			Position = UDim2.fromScale(0.5, 0.18),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
		}, {
			Button = e(TextButton, {
				Text = "Create Game",
				Variant = "primary",
				Size = UDim2.fromScale(1, 1),
				OnClick = function()
					setShowCreateModal(true)
				end,
			}),
		}),
		
		-- Server list
		ServerList = e("ScrollingFrame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			CanvasSize = UDim2.fromScale(0, 0),
			Position = UDim2.fromScale(0.5, 0.62),
			ScrollBarThickness = 6,
			ScrollBarImageColor3 = Color3.fromRGB(249, 0, 149),
			Size = UDim2.fromScale(0.809375, 0.68),
			ZIndex = 2,
		}, entries),
		
		-- Create lobby modal
		CreateModal = showCreateModal and e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.5,
			ZIndex = 10,
		}, {
			ModalPanel = e("Frame", {
				Size = UDim2.fromScale(0.4, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(35, 55, 100),
				ZIndex = 11,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0.03, 0),
				}),
				
				UIStroke = e("UIStroke", {
					Color = Color3.new(1, 1, 1),
					Thickness = 3,
				}),
				
				Title = e("TextLabel", {
					Size = UDim2.fromScale(1, 0.15),
					BackgroundTransparency = 1,
					Text = "Create Game",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					ZIndex = 11,
					FontFace = Font.new(
						"rbxassetid://11702779517",
						Enum.FontWeight.Heavy,
						Enum.FontStyle.Italic
					),
				}, {
					UIPadding = e("UIPadding", {
						PaddingTop = UDim.new(0.2, 0),
					}),
				}),
				
				-- Game name input
				NameLabel = e("TextLabel", {
					Size = UDim2.fromScale(0.3, 0.1),
					Position = UDim2.fromScale(0.1, 0.2),
					BackgroundTransparency = 1,
					Text = "Game Name:",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 11,
					FontFace = Font.new(
						"rbxassetid://11702779517",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
				}),
				
				NameInput = e("TextBox", {
					Size = UDim2.fromScale(0.55, 0.1),
					Position = UDim2.fromScale(0.4, 0.2),
					BackgroundColor3 = Color3.fromRGB(50, 75, 130),
					Text = lobbyName,
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					PlaceholderText = "Enter game name...",
					PlaceholderColor3 = Color3.fromRGB(150, 150, 180),
					ClearTextOnFocus = false,
					ZIndex = 11,
					FontFace = Font.new(
						"rbxassetid://11702779517",
						Enum.FontWeight.Medium,
						Enum.FontStyle.Normal
					),
					[React.Event.Changed] = function(rbx)
						setLobbyName(rbx.Text)
					end,
				}, {
					UICorner = e("UICorner", {
						CornerRadius = UDim.new(0.2, 0),
					}),
					UIPadding = e("UIPadding", {
						PaddingLeft = UDim.new(0.05, 0),
						PaddingRight = UDim.new(0.05, 0),
					}),
				}),
				
				-- Max players
				PlayersLabel = e("TextLabel", {
					Size = UDim2.fromScale(0.3, 0.1),
					Position = UDim2.fromScale(0.1, 0.35),
					BackgroundTransparency = 1,
					Text = "Max Players:",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 11,
					FontFace = Font.new(
						"rbxassetid://11702779517",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
				}),
				
				PlayersMinus = e("Frame", {
					Size = UDim2.fromScale(0.1, 0.1),
					Position = UDim2.fromScale(0.4, 0.35),
					BackgroundTransparency = 1,
					ZIndex = 11,
				}, {
					Button = e(TextButton, {
						Text = "-",
						Variant = "secondary",
						Size = UDim2.fromScale(1, 1),
						OnClick = function()
							setMaxPlayers(math.max(1, maxPlayers - 1)) -- Allow solo play
						end,
					}),
				}),
				
				PlayersCount = e("TextLabel", {
					Size = UDim2.fromScale(0.15, 0.1),
					Position = UDim2.fromScale(0.52, 0.35),
					BackgroundTransparency = 1,
					Text = tostring(maxPlayers),
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					ZIndex = 11,
					FontFace = Font.new(
						"rbxassetid://11702779517",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
				}),
				
				PlayersPlus = e("Frame", {
					Size = UDim2.fromScale(0.1, 0.1),
					Position = UDim2.fromScale(0.68, 0.35),
					BackgroundTransparency = 1,
					ZIndex = 11,
				}, {
					Button = e(TextButton, {
						Text = "+",
						Variant = "secondary",
						Size = UDim2.fromScale(1, 1),
						OnClick = function()
							setMaxPlayers(math.min(6, maxPlayers + 1))
						end,
					}),
				}),
				
				-- Private toggle
				PrivateLabel = e("TextLabel", {
					Size = UDim2.fromScale(0.3, 0.1),
					Position = UDim2.fromScale(0.1, 0.5),
					BackgroundTransparency = 1,
					Text = "Private:",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 11,
					FontFace = Font.new(
						"rbxassetid://11702779517",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
				}),
				
				PrivateToggle = e("Frame", {
					Size = UDim2.fromScale(0.2, 0.1),
					Position = UDim2.fromScale(0.4, 0.5),
					BackgroundTransparency = 1,
					ZIndex = 11,
				}, {
					Button = e(TextButton, {
						Text = isPrivate and "Yes" or "No",
						Variant = isPrivate and "primary" or "secondary",
						Size = UDim2.fromScale(1, 1),
						OnClick = function()
							setIsPrivate(not isPrivate)
						end,
					}),
				}),
				
				-- Buttons
				CancelButton = e("Frame", {
					Size = UDim2.fromScale(0.35, 0.12),
					Position = UDim2.fromScale(0.15, 0.75),
					BackgroundTransparency = 1,
					ZIndex = 11,
				}, {
					Button = e(TextButton, {
						Text = "Cancel",
						Variant = "secondary",
						Size = UDim2.fromScale(1, 1),
						OnClick = function()
							setShowCreateModal(false)
						end,
					}),
				}),
				
				CreateButton = e("Frame", {
					Size = UDim2.fromScale(0.35, 0.12),
					Position = UDim2.fromScale(0.55, 0.75),
					BackgroundTransparency = 1,
					ZIndex = 11,
				}, {
					Button = e(TextButton, {
						Text = "Create",
						Variant = "primary",
						Size = UDim2.fromScale(1, 1),
						OnClick = function()
							ScrabbleServiceClient:createLobby(lobbyName, maxPlayers, isPrivate)
							setShowCreateModal(false)
						end,
					}),
				}),
			}),
		}) or nil,
	})
end
