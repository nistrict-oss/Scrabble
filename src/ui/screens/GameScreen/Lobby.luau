--[[
	Lobby.luau
	
	Waiting room screen before the game starts. Shows:
	- Lobby name and code (if private)
	- List of players with ready status
	- Ready/Start buttons
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.React)
local GameConstants = require(ReplicatedStorage.Shared.Modules.Core.GameConstants)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)
local ScrabbleServiceClient = require(ReplicatedStorage.Shared.Services.ScrabbleService.ScrabbleServiceClient)

local e = React.createElement

local LocalPlayer = Players.LocalPlayer

export type LobbyProps = {
	LobbyState: any, -- Lobby state from server
	OnLeave: (() -> ())?,
}

return function(props: LobbyProps)
	local lobby = props.LobbyState
	local groupRef = React.useRef(nil :: CanvasGroup?)

	-- Entrance Animation
	React.useEffect(function()
		local group = groupRef.current
		if not group then return end

		-- Parent TransitionFrame handles fade, we add a subtle slide up
		local originalPos = UDim2.fromScale(0.5, 0.5)
		group.Position = UDim2.new(0.5, 0, 0.5, 20)
		group.GroupTransparency = 1
		
		TweenService:Create(group, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = originalPos,
			GroupTransparency = 0
		}):Play()
	end, {})
	
	if not lobby then
		return e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			Loading = e("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "Loading lobby...",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				FontFace = Font.new(
					"rbxassetid://11702779517",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Italic
				),
			}),
		})
	end
	
	local isHost = lobby.HostUserId == LocalPlayer.UserId
	local lobbyPlayers = lobby.Players or {}
	local readyStatus = lobby.Ready or {}
	
	-- Helper to check ready status (handles string/number key conversion from network)
	local function isPlayerReady(userId: number): boolean
		return readyStatus[userId] == true or readyStatus[tostring(userId)] == true
	end
	
	-- Check if all players are ready (for start button)
	-- Solo play is allowed (1 player), so just check if everyone is ready
	local allReady = #lobbyPlayers >= 1
	for _, player in ipairs(lobbyPlayers) do
		if not isPlayerReady(player.UserId) then
			allReady = false
			break
		end
	end
	
	-- Build player list
	local playerEntries = {}
	for i, player in ipairs(lobbyPlayers) do
		local isReady = isPlayerReady(player.UserId)
		local isCurrentPlayer = player.UserId == LocalPlayer.UserId
		local isLobbyHost = player.UserId == lobby.HostUserId
		
		playerEntries["Player_" .. i] = e("Frame", {
			Size = UDim2.new(1, 0, 0, 60),
			BackgroundColor3 = if isCurrentPlayer 
				then Color3.fromRGB(60, 90, 150)
				else Color3.fromRGB(45, 70, 120),
			LayoutOrder = i,
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0.15, 0),
			}),
			
			UIStroke = e("UIStroke", {
				Color = Color3.new(1, 1, 1),
				Thickness = if isCurrentPlayer then 2 else 1,
				Transparency = if isCurrentPlayer then 0 else 0.7,
			}),
			
			UIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.1, 0),
				PaddingTop = UDim.new(0.1, 0),
				PaddingLeft = UDim.new(0.05, 0),
				PaddingRight = UDim.new(0.05, 0),
			}),
			
			-- Avatar
			Avatar = e("ImageLabel", {
				Size = UDim2.fromScale(0.12, 1),
				BackgroundColor3 = Color3.fromRGB(80, 90, 120),
				Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150",
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0.5, 0),
				}),
				UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
					AspectRatio = 1,
				}),
			}),
			
			-- Name
			Name = e("TextLabel", {
				Size = UDim2.fromScale(0.5, 0.6),
				Position = UDim2.fromScale(0.15, 0),
				BackgroundTransparency = 1,
				Text = player.Name .. (isLobbyHost and " (Host)" or ""),
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Font.new(
					"rbxassetid://11702779517",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
			}),
			
			-- Ready status
			ReadyStatus = e("TextLabel", {
				Size = UDim2.fromScale(0.25, 0.6),
				Position = UDim2.fromScale(0.75, 0.2),
				BackgroundTransparency = 1,
				Text = if isReady then "✓ Ready" else "Not Ready",
				TextColor3 = if isReady 
					then Color3.fromRGB(100, 255, 100)
					else Color3.fromRGB(255, 150, 150),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Right,
				FontFace = Font.new(
					"rbxassetid://11702779517",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
			}),
		})
	end
	
	playerEntries["UIListLayout"] = e("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	})
	
	return e("CanvasGroup", {
		ref = groupRef,
		Size = UDim2.fromScale(0.5, 0.7),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(35, 55, 100),
		GroupTransparency = 1, -- Animated
	}, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0.02, 0),
		}),
		
		UIStroke = e("UIStroke", {
			Color = Color3.new(1, 1, 1),
			Thickness = 3,
		}),
		
		-- Header
		Header = e("Frame", {
			Size = UDim2.fromScale(1, 0.15),
			BackgroundColor3 = Color3.fromRGB(255,255,255),
		}, {
		UIGradient = e("UIGradient", {
				Color = ColorSequence.new(GameConstants.Gradients.buttonActive),
				Rotation = 90,
			}),

			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0.1, 0),
			}),
			
			Title = e("TextLabel", {
				Size = UDim2.fromScale(1, 0.6),
				Position = UDim2.fromScale(0, 0.1),
				BackgroundTransparency = 1,
				Text = lobby.Name or "Game Lobby",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				FontFace = Font.new(
					"rbxassetid://11702779517",
					Enum.FontWeight.Heavy,
					Enum.FontStyle.Italic
				),
			}, {
				UIPadding = e("UIPadding", {
					PaddingLeft = UDim.new(0.05, 0),
					PaddingRight = UDim.new(0.05, 0),
				}),
			}),
			
			Code = lobby.Private and e("TextLabel", {
				Size = UDim2.fromScale(1, 0.3),
				Position = UDim2.fromScale(0, 0.65),
				BackgroundTransparency = 1,
				Text = "Code: " .. (lobby.Code or "???"),
				TextColor3 = Color3.fromRGB(255, 220, 180),
				TextScaled = true,
				FontFace = Font.new(
					"rbxassetid://11702779517",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
			}, {
				UIPadding = e("UIPadding", {
					PaddingLeft = UDim.new(0.05, 0),
					PaddingRight = UDim.new(0.05, 0),
				}),
			}) or nil,
		}),
		
		-- Player count
		PlayerCount = e("TextLabel", {
			Size = UDim2.fromScale(1, 0.06),
			Position = UDim2.fromScale(0, 0.16),
			BackgroundTransparency = 1,
			Text = "Players: " .. #lobbyPlayers .. "/" .. (lobby.MaxPlayers or 4),
			TextColor3 = Color3.fromRGB(180, 180, 200),
			TextScaled = true,
			FontFace = Font.new(
				"rbxassetid://11702779517",
				Enum.FontWeight.Medium,
				Enum.FontStyle.Normal
			),
		}),
		
		-- Player list
		PlayerList = e("ScrollingFrame", {
			Size = UDim2.fromScale(0.9, 0.5),
			Position = UDim2.fromScale(0.5, 0.45),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			ScrollBarThickness = 4,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.fromScale(0, 0),
		}, playerEntries),
		
		-- Buttons
		ButtonContainer = e("Frame", {
			Size = UDim2.fromScale(0.9, 0.12),
			Position = UDim2.fromScale(0.5, 0.88),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
		}, {
			UIListLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0.02, 0),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),
			
			LeaveButton = e("Frame", {
				Size = UDim2.fromScale(0.3, 1),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, {
				Button = e(TextButton, {
					Text = "Leave",
					Variant = "secondary",
					Size = UDim2.fromScale(1, 1),
					OnClick = function()
						ScrabbleServiceClient:leaveLobby()
						if props.OnLeave then
							props.OnLeave()
						end
					end,
				}),
			}),
			
			ReadyButton = e("Frame", {
				Size = UDim2.fromScale(0.3, 1),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				Button = e(TextButton, {
					Text = if isPlayerReady(LocalPlayer.UserId) then "Unready" else "Ready",
					Variant = if isPlayerReady(LocalPlayer.UserId) then "secondary" else "primary",
					Size = UDim2.fromScale(1, 1),
					OnClick = function()
						ScrabbleServiceClient:toggleReady()
					end,
				}),
			}),
			
			StartButton = isHost and e("Frame", {
				Size = UDim2.fromScale(0.3, 1),
				BackgroundTransparency = 1,
				LayoutOrder = 3,
			}, {
				Button = e(TextButton, {
					Text = "Start",
					Variant = "primary",
					Size = UDim2.fromScale(1, 1),
					Disabled = not allReady,
					OnClick = function()
						ScrabbleServiceClient:startGame()
					end,
				}),
			}) or nil,
		}),
	})
end

