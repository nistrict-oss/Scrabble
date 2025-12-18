local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.React)
local GameConstants = require(ReplicatedStorage.Shared.Modules.Core.GameConstants)
local ScrabbleServiceClient = require(ReplicatedStorage.Shared.Services.ScrabbleService.ScrabbleServiceClient)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)

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
		if lobby and lobby.Players then
			for _, player in ipairs(lobby.Players) do
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
	end, { game.Scores, lobby.Players })

	local winnerId = game.Winner
	local winnerName = "No One"
	if winnerId then
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
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1, -- Animated
		ZIndex = 100,
	}, {
		MainPanel = e("CanvasGroup", {
			ref = groupRef,
			Size = UDim2.fromScale(0.4, 0.7),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			GroupTransparency = 1, -- Animated
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0.05, 0),
			}),
			UIGradient = e("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new(GameConstants.Gradients.frame),
			}),
			UIStroke = e("UIStroke", {
				Color = Color3.new(1, 1, 1),
				Thickness = 4,
			}),
			UIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.05, 0),
				PaddingTop = UDim.new(0.05, 0),
				PaddingLeft = UDim.new(0.05, 0),
				PaddingRight = UDim.new(0.05, 0),
			}),

			Header = e("TextLabel", {
				Size = UDim2.fromScale(1, 0.15),
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
					Thickness = 2,
				}),
			}),

			WinnerSection = e("Frame", {
				Size = UDim2.fromScale(1, 0.2),
				Position = UDim2.fromScale(0, 0.18),
				BackgroundTransparency = 1,
			}, {
				TrophyIcon = e("ImageLabel", {
					Size = UDim2.fromScale(0.2, 0.8),
					Position = UDim2.fromScale(0.4, 0),
					BackgroundTransparency = 1,
					Image = "rbxassetid://125569767011561",
					ImageColor3 = Color3.new(1, 0.9, 0),
				}),
				WinnerText = e("TextLabel", {
					Size = UDim2.fromScale(1, 0.4),
					Position = UDim2.fromScale(0, 0.7),
					BackgroundTransparency = 1,
					Text = winnerName .. " WINS!",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					FontFace = Font.new(
						"rbxassetid://11702779517",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
				}),
			}),

			ResultsList = e("ScrollingFrame", {
				Size = UDim2.fromScale(1, 0.45),
				Position = UDim2.fromScale(0, 0.4),
				BackgroundTransparency = 1,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollBarThickness = 2,
				ScrollBarImageColor3 = Color3.new(1, 1, 1),
			}, {
				UIListLayout = e("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 5),
				}),
				
				unpack(React.useMemo(function()
					local entries = {}
					for i, res in ipairs(results) do
						table.insert(entries, e("Frame", {
							Size = UDim2.new(1, 0, 0, 40),
							BackgroundColor3 = if i == 1 then Color3.fromRGB(249, 0, 149) else Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = if i == 1 then 0.2 else 0.9,
							LayoutOrder = i,
						}, {
							UICorner = e("UICorner", { CornerRadius = UDim.new(0.2, 0) }),
							Rank = e("TextLabel", {
								Size = UDim2.fromScale(0.1, 1),
								BackgroundTransparency = 1,
								Text = "#" .. i,
								TextColor3 = Color3.new(1, 1, 1),
								TextScaled = true,
								FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
							}),
							Name = e("TextLabel", {
								Size = UDim2.fromScale(0.6, 1),
								Position = UDim2.fromScale(0.15, 0),
								BackgroundTransparency = 1,
								Text = res.Name,
								TextColor3 = Color3.new(1, 1, 1),
								TextScaled = true,
								TextXAlignment = Enum.TextXAlignment.Left,
								FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
							}),
							Score = e("TextLabel", {
								Size = UDim2.fromScale(0.25, 1),
								Position = UDim2.fromScale(0.75, 0),
								BackgroundTransparency = 1,
								Text = res.Score .. " pts",
								TextColor3 = Color3.new(1, 1, 1),
								TextScaled = true,
								TextXAlignment = Enum.TextXAlignment.Right,
								FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy),
							}),
						}))
					end
					return entries
				end, { results })),
			}),

			LeaveButton = e("Frame", {
				Size = UDim2.fromScale(0.6, 0.12),
				Position = UDim2.fromScale(0.5, 0.95),
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
			}, {
				Button = e(TextButton, {
					Text = "Back to Menu",
					Variant = "primary",
					Size = UDim2.fromScale(1, 1),
					OnClick = function()
						ScrabbleServiceClient:leaveLobby()
					end,
				}),
			}),
		}),
	})
end
