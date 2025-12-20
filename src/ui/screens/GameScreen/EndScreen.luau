local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.React)
local GameConstants = require(ReplicatedStorage.Shared.Modules.Core.GameConstants)
local ScrabbleServiceClient = require(ReplicatedStorage.Shared.Services.ScrabbleService.ScrabbleServiceClient)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)
local SoundUtils = require(ReplicatedStorage.Shared.Modules.Core.SoundUtils)
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local e = React.createElement

export type EndScreenProps = {
	GameState: any,
	LobbyState: any,
	OnLeave: () -> (),
}

return function(props: EndScreenProps)
	local game = props.GameState
	local lobby = props.LobbyState
	
	-- Animation Refs
	local backdropRef = React.useRef(nil :: Frame?)
	local groupRef = React.useRef(nil :: CanvasGroup?)

	-- Extract and sort players by score
	local results = React.useMemo(function()
		local res = {}
		local playerSource = if game and game.FinalPlayers then game.FinalPlayers else (lobby and lobby.Players or {})
		
		if game and game.Scores then
			for _, player in ipairs(playerSource) do
				local score = game.Scores[tostring(player.UserId)] or game.Scores[player.UserId] or 0
				table.insert(res, {
					UserId = player.UserId,
					Name = player.Name,
					Score = score,
				})
			end
			table.sort(res, function(a, b)
				return a.Score > b.Score
			end)
		end
		return res
	end, { game, lobby })

	local winnerId = game and game.Winner
	local winnerName = "No One"
	if winnerId and #results > 0 then
		for _, p in ipairs(results) do
			if p.UserId == winnerId then
				winnerName = p.Name
				break
			end
		end
	end

	-- Entrance Animation
	React.useEffect(function()
		local backdrop = backdropRef.current
		local group = groupRef.current
		if not backdrop or not group then return end

		-- Reset states
		backdrop.BackgroundTransparency = 1
		group.GroupTransparency = 1
		
		-- Use a UIScale for pop-in effect
		local uiScale = group:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", group)
		uiScale.Scale = 0.8

		-- Backdrop Fade
		TweenService:Create(backdrop, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.5
		}):Play()

		-- Panel Pop-in
		TweenService:Create(group, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			GroupTransparency = 0
		}):Play()
		
		TweenService:Create(uiScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1
		}):Play()

	end, {})

	return e("Frame", {
		ref = backdropRef,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0,0,0),
		BackgroundTransparency = 1, -- Animated
		ZIndex = 100,
	}, {
		MainPanel = e("CanvasGroup", {
			ref = groupRef,
			Size = UDim2.fromScale(0.45, 0.75),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(20, 30, 60),
			GroupTransparency = 1, -- Animated
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0.04, 0),
			}),
			UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 1,
			}),
			UIStroke = e("UIStroke", {
				Color = Color3.new(1, 1, 1),
				Thickness = 3,
				Transparency = 0.2,
			}),
			UIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.06, 0),
				PaddingTop = UDim.new(0.06, 0),
				PaddingLeft = UDim.new(0.06, 0),
				PaddingRight = UDim.new(0.06, 0),
			}),

			Header = e("TextLabel", {
				Size = UDim2.fromScale(1, 0.12),
				BackgroundTransparency = 1,
				Text = "GAME OVER",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				FontFace = Font.new(
					"rbxassetid://11702779517",
					Enum.FontWeight.Heavy,
					Enum.FontStyle.Italic
				),
			}, {
				UIStroke = e("UIStroke", {
					Color = Color3.fromRGB(249, 0, 149),
					Thickness = 3,
				}),
			}),

			WinnerSection = e("Frame", {
				Size = UDim2.fromScale(1, 0.25),
				Position = UDim2.fromScale(0, 0.15),
				BackgroundTransparency = 1,
			}, {
				WinnerText = e("TextLabel", {
					Size = UDim2.fromScale(1, 0.35),
					Position = UDim2.fromScale(0, 0),
					BackgroundTransparency = 1,
					Text = winnerName:upper() .. " WINS!",
					TextColor3 = Color3.fromRGB(255, 230, 100),
					TextScaled = true,
					FontFace = Font.new(
						"rbxassetid://11702779517",
						Enum.FontWeight.Heavy,
						Enum.FontStyle.Normal
					),
				}),
			}),

			ResultsList = e("ScrollingFrame", {
				Size = UDim2.fromScale(1, 0.6),
				Position = UDim2.fromScale(0, 0.25),
				BackgroundTransparency = 1,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollBarThickness = 0,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				Active = true,
			}, {
				UIListLayout = e("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0.03,0),
				}),

				UIPadding = e("UIPadding", {
					PaddingTop = UDim.new(0.01, 0),
					PaddingLeft = UDim.new(0.05, 0),
					PaddingRight = UDim.new(0.05, 0),
				}),
				
				unpack(React.useMemo(function()
					local entries = {}
					for i, res in ipairs(results) do
						local isWinner = i == 1
						local rankColor = if i == 1 then Color3.fromRGB(255, 215, 0)
										  elseif i == 2 then Color3.fromRGB(192, 192, 192)
										  elseif i == 3 then Color3.fromRGB(205, 127, 50)
										  else Color3.fromRGB(180, 180, 200)

						table.insert(entries, e("Frame", {
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 0.95,
							LayoutOrder = i,
						}, {
							UICorner = e("UICorner", { CornerRadius = UDim.new(0.2, 0) }),
							UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
								AspectRatio = 7,
							}),
							UIStroke = e("UIStroke", {
								Color = rankColor,
								Thickness = if i <= 3 then 2 else 1,
								Transparency = if i <= 3 then 0 else 0.5,
							}),
							
							UIPadding = e("UIPadding", {
								PaddingLeft = UDim.new(0.04, 0),
								PaddingRight = UDim.new(0.04, 0),
							}),

							Rank = e("TextLabel", {
								Size = UDim2.fromScale(0.1, 1),
								BackgroundTransparency = 1,
								Text = i,
								TextColor3 = rankColor,
								TextScaled = true,
								FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy),
							}),
							
							Avatar = e("ImageLabel", {
								Size = UDim2.fromScale(0.12, 0.8),
								Position = UDim2.fromScale(0.12, 0.1),
								BackgroundTransparency = 1,
								ZIndex = 2,
							}, {
								ActualPFP = e("ImageLabel", {
									Size = UDim2.fromScale(1, 1),
									BackgroundTransparency = 1,
									Image = "rbxthumb://type=AvatarHeadShot&id=" .. res.UserId .. "&w=150&h=150",
								}, {
									UICorner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
								})
							}),

							Name = e("TextLabel", {
								Size = UDim2.fromScale(0.5, 1),
								Position = UDim2.fromScale(0.28, 0),
								BackgroundTransparency = 1,
								Text = res.Name,
								TextColor3 = Color3.new(1, 1, 1),
								TextScaled = true,
								TextXAlignment = Enum.TextXAlignment.Left,
								FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
							}),
							Score = e("TextLabel", {
								Size = UDim2.fromScale(0.2, 1),
								Position = UDim2.fromScale(0.8, 0),
								BackgroundTransparency = 1,
								Text = res.Score,
								TextColor3 = if isWinner then Color3.new(1, 1, 1) else rankColor,
								TextScaled = true,
								TextXAlignment = Enum.TextXAlignment.Right,
								FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy),
							}, {
								Suffix = e("TextLabel", {
									Size = UDim2.fromScale(1, 0.4),
									Position = UDim2.fromScale(0, 0.6),
									BackgroundTransparency = 1,
									Text = "pts",
									TextColor3 = if isWinner then Color3.new(1, 1, 1) else rankColor,
									TextTransparency = 0.5,
									TextScaled = true,
									TextXAlignment = Enum.TextXAlignment.Right,
									Visible = false, -- Clean look
								})
							}),
						}))
					end
					return entries
				end, { results })),
			}),

			LeaveButton = e("Frame", {
				Size = UDim2.fromScale(0.8, 0.11),
				Position = UDim2.fromScale(0.5, 0.98),
				AnchorPoint = Vector2.new(0.5, 1),

				BackgroundTransparency = 1,
			}, {
				Button = e(TextButton, {
					Text = "Back to Menu",
					Variant = "primary",
					Size = UDim2.fromScale(1, 1),
					OnClick = function()
						if props.OnLeave then
							props.OnLeave()
						end
						ScrabbleServiceClient:leaveLobby()
					end,
				}),
			}),
		}),
	})
end
