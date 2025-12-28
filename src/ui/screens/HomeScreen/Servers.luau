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
local CreateGameScreen = require(ReplicatedStorage.UI.screens.HomeScreen.CreateGameScreen)
local StyledPanel = require(ReplicatedStorage.UI.components.frames.StyledPanel)
local AnimatedModal = require(ReplicatedStorage.UI.components.frames.AnimatedModal)

local e = React.createElement

local useScrabbleState = GameStateHook.useScrabbleState
local LocalPlayer = Players.LocalPlayer

return function(_props)
	local scrabbleState = useScrabbleState()
	local lobbies = scrabbleState.lobbies or {}
	local showCreateModal, setShowCreateModal = React.useState(false)

	local joiningLobby, setJoiningLobby = React.useState(nil :: any?)
	local joinCode, setJoinCode = React.useState("")

	-- Build lobby entries
	local entries = {}

	for i, lobby in ipairs(lobbies) do
		entries["Lobby_" .. i] = e(ServerEntry, {
			LobbyName = lobby.Name,
			HostName = lobby.HostName or "Unknown",
			HostUserId = lobby.HostUserId,
			PlayerCount = lobby.Players or 0,
			MaxPlayers = lobby.MaxPlayers or 4,
			IsPrivate = lobby.Private,
			Code = lobby.Code,
			Phase = lobby.Phase,
			LayoutOrder = i + 1,
			OnJoin = function()
				if lobby.Private then
					setJoiningLobby(lobby)
					setJoinCode("")
				else
					ScrabbleServiceClient:joinLobby(lobby.Id)
				end
			end,
			OnSpectate = function()
				ScrabbleServiceClient:spectateLobby(lobby.Id)
			end,
		})
	end

	entries["UIListLayout"] = e("UIListLayout", {
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 8),
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

			UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 3,
			}),
		}),

		-- Server list
		ServerList = e(
			"ScrollingFrame",
			{
				AnchorPoint = Vector2.new(0.5, 0.5),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				CanvasSize = UDim2.fromScale(0, 0),
				Position = UDim2.fromScale(0.5, 0.65),
				ScrollBarThickness = 0,
				ScrollBarImageColor3 = Color3.fromRGB(249, 0, 149),
				Size = UDim2.fromScale(0.9, 0.75),
				ZIndex = 2,
			},
			entries,
			{
				UIPadding = e("UIPadding", {
					PaddingBottom = UDim.new(0, 50),
					PaddingTop = UDim.new(0, 10),
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
				}),
			}
		),

		-- Empty state (shown when no lobbies exist)
		EmptyState = #lobbies == 0 and e("TextLabel", {
			Size = UDim2.fromScale(0.6, 0.15),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Text = "No games available.\nCreate one to get started!",
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			ZIndex = 5,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium, Enum.FontStyle.Italic),
		}) or nil,

		-- Create lobby modal (always mounted to allow exit animation)
		CreateModal = e(CreateGameScreen, {
			Visible = showCreateModal,
			OnClose = function()
				setShowCreateModal(false)
			end,
		}),

		-- Join Private Modal (with animation)
		JoinModal = e(AnimatedModal, {
			Visible = joiningLobby ~= nil,
			Size = UDim2.fromScale(0.45, 0.55),
			ZIndex = 100,
		}, {
			Modal = joiningLobby and e(StyledPanel, {
				AspectRatio = 1.2,
				ZIndex = 101,
				Children = {
					Title = e("TextLabel", {
						Size = UDim2.fromScale(1, 0.2),
						BackgroundTransparency = 1,
						Text = "Private Game",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
						ZIndex = 102,
						FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
					}, {
						UIPadding = e("UIPadding", { PaddingTop = UDim.new(0.2, 0) }),
					}),

					Subtitle = e("TextLabel", {
						Size = UDim2.fromScale(0.9, 0.1),
						Position = UDim2.fromScale(0.05, 0.25),
						BackgroundTransparency = 1,
						Text = "Enter code for: " .. (joiningLobby and joiningLobby.Name or ""),
						TextColor3 = Color3.fromRGB(200, 200, 220),
						TextScaled = true,
						ZIndex = 102,
						FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
					}),

					CodeInput = e("TextBox", {
						Size = UDim2.fromScale(0.7, 0.15),
						Position = UDim2.fromScale(0.15, 0.45),
						BackgroundColor3 = Color3.fromRGB(50, 75, 130),
						Text = joinCode,
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
						PlaceholderText = "CODE",
						PlaceholderColor3 = Color3.fromRGB(150, 150, 180),
						ClearTextOnFocus = false,
						ZIndex = 102,
						FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
						[React.Change.Text] = function(rbx)
							setJoinCode(string.upper(rbx.Text))
						end,
					}, {
						UICorner = e("UICorner", { CornerRadius = UDim.new(0.3, 0) }),
						UIStroke = e("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1 }),
						UIPadding = e(
							"UIPadding",
							{ PaddingLeft = UDim.new(0.05, 0), PaddingRight = UDim.new(0.05, 0) }
						),
					}),

					ButtonContainer = e("Frame", {
						Size = UDim2.fromScale(0.9, 0.2),
						Position = UDim2.fromScale(0.05, 0.7),
						BackgroundTransparency = 1,
						ZIndex = 102,
					}, {
						UIListLayout = e("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							Padding = UDim.new(0.05, 0),
							SortOrder = Enum.SortOrder.LayoutOrder,
						}),

						Cancel = e(TextButton, {
							Text = "Back",
							Variant = "secondary",
							Size = UDim2.fromScale(0.4, 0.8),
							LayoutOrder = 1,
							OnClick = function()
								setJoiningLobby(nil)
							end,
						}),

						Join = e(TextButton, {
							Text = "Join",
							Variant = "primary",
							Size = UDim2.fromScale(0.4, 0.8),
							LayoutOrder = 2,
							IsDisabled = #joinCode == 0,
							OnClick = function()
								ScrabbleServiceClient:joinLobby(joinCode)
								setJoiningLobby(nil)
							end,
						}),
					}),
				},
			}) or nil,
		}),
	})
end
