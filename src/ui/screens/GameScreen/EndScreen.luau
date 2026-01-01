local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.React)
local ScrabbleServiceClient = require(ReplicatedStorage.Shared.Services.ScrabbleService.ScrabbleServiceClient)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)
local SoundUtils = require(ReplicatedStorage.Shared.Modules.Core.SoundUtils)
local TransitionFrameModule = require(ReplicatedStorage.UI.components.frames.TransitionFrame)
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local e = React.createElement

local function StatRow(props: { index: number, label: string, value: any, icon: string, color: Color3 })
	local innerRef = React.useRef(nil :: Frame?)

	local isMounted = React.useRef(true)
	local transition = React.useContext(TransitionFrameModule.Context)

	React.useEffect(function()
		return function()
			isMounted.current = false
		end
	end, {})

	React.useEffect(function()
		local inner = innerRef.current
		if not inner then
			return
		end
		-- Start off-screen right and invisible
		inner.Position = UDim2.fromScale(1.5, 0)

		-- Voosh in with delay based on index
		task.delay(0.1 + props.index * 0.12, function()
			if not isMounted.current or transition.isExiting then
				return
			end
			SoundUtils.playWoosh()
			TweenService:Create(inner, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.fromScale(0, 0),
			}):Play()
		end)
	end, {})

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		LayoutOrder = props.index,
	}, {
		UIAspectRatioConstraint = e("UIAspectRatioConstraint", { AspectRatio = 7 }),

		Inner = e("Frame", {
			ref = innerRef,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 0.9,
			BackgroundColor3 = Color3.new(1, 1, 1),
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0.2, 0) }),
			UIStroke = e("UIStroke", { Color = props.color, Thickness = 2, Transparency = 0.5 }),
			UIPadding = e("UIPadding", { PaddingLeft = UDim.new(0.04, 0), PaddingRight = UDim.new(0.04, 0) }),

			Icon = e("ImageLabel", {
				Size = UDim2.fromScale(0.1, 0.6),
				Position = UDim2.fromScale(0, 0.2),
				BackgroundTransparency = 1,
				Image = props.icon,
				ImageColor3 = props.color,
			}),

			Label = e("TextLabel", {
				Size = UDim2.fromScale(0.5, 1),
				Position = UDim2.fromScale(0.15, 0),
				BackgroundTransparency = 1,
				Text = props.label,
				TextColor3 = Color3.fromRGB(200, 200, 220),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
			}),

			Value = e("TextLabel", {
				Size = UDim2.fromScale(0.3, 1),
				Position = UDim2.fromScale(0.7, 0),
				BackgroundTransparency = 1,
				Text = tostring(props.value),
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Right,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy),
			}),
		}),
	})
end

export type EndScreenProps = {
	GameState: any,
	LobbyState: any,
	OnLeave: () -> (),
	IsEliminated: boolean?,
}

return function(props: EndScreenProps)
	local gameState = props.GameState
	local lobby = props.LobbyState

	-- Animation Refs
	local backdropRef = React.useRef(nil :: Frame?)
	local groupRef = React.useRef(nil :: Frame?)

	local page, setPage = React.useState("Results" :: "Results" | "Stats")

	-- Extract and sort players by score
	local results = React.useMemo(function()
		local res = {}
		local playerSource = if gameState and gameState.FinalPlayers
			then gameState.FinalPlayers
			else (lobby and lobby.Players or {})

		if gameState and gameState.Scores then
			for _, player in ipairs(playerSource) do
				local score = gameState.Scores[tostring(player.UserId)] or gameState.Scores[player.UserId] or 0
				local reward = if gameState.Rewards
					then (gameState.Rewards[tostring(player.UserId)] or gameState.Rewards[player.UserId] or 0)
					else 0
				table.insert(res, {
					UserId = player.UserId,
					Name = player.Name,
					Score = score,
					Reward = reward,
				})
			end
			table.sort(res, function(a, b)
				return a.Score > b.Score
			end)
		end
		return res
	end, { gameState, lobby })

	local myStats = React.useMemo(function()
		if not gameState then
			return nil
		end
		local stats = if gameState.SessionStats
			then (gameState.SessionStats[tostring(LocalPlayer.UserId)] or gameState.SessionStats[LocalPlayer.UserId])
			else nil
		local score = gameState.Scores[tostring(LocalPlayer.UserId)] or gameState.Scores[LocalPlayer.UserId] or 0
		local coins = if gameState.Rewards
			then (gameState.Rewards[tostring(LocalPlayer.UserId)] or gameState.Rewards[LocalPlayer.UserId] or 0)
			else 0

		return {
			{
				Label = "Coins Earned",
				Value = coins,
				Icon = "rbxassetid://137904107688579",
				Color = Color3.fromRGB(255, 230, 80),
			},
			{
				Label = "Total Points",
				Value = score,
				Icon = "rbxassetid://12814801644",
				Color = Color3.fromRGB(100, 200, 255),
			},
			{
				Label = "Words Placed",
				Value = stats and stats.WordsPlaced or 0,
				Icon = "rbxassetid://15227705494",
				Color = Color3.fromRGB(150, 255, 150),
			},
			{
				Label = "Longest Word",
				Value = if stats and stats.LongestWord ~= "" then stats.LongestWord else "--",
				Icon = "rbxassetid://15227705494",
				Color = Color3.fromRGB(255, 150, 255),
			},
			{
				Label = "Best Word",
				Value = if stats and stats.BestWord ~= ""
					then string.format("%s (%d)", stats.BestWord, stats.BestWordScore)
					else "--",
				Icon = "rbxassetid://12814801644",
				Color = Color3.fromRGB(255, 200, 100),
			},
		}
	end, { gameState })

	local winnerId = gameState and gameState.Winner
	local winnerName = "No One"
	if winnerId and #results > 0 then
		for _, p in ipairs(results) do
			if p.UserId == winnerId then
				winnerName = p.Name
				break
			end
		end
	end

	local localPlayerResigned = gameState and gameState.ResignedUserId == LocalPlayer.UserId
	local isEliminated = props.IsEliminated == true
	local gameNotEnded = gameState and gameState.Phase ~= "ended"

	local statusMessage = "GAME OVER"
	local statusColor = Color3.fromRGB(255, 230, 100) -- Gold/Yellow

	-- Handle eliminated player viewing stats before game ends
	if isEliminated and gameNotEnded then
		statusMessage = "ELIMINATED"
		statusColor = Color3.fromRGB(255, 80, 80) -- Red
	elseif localPlayerResigned then
		statusMessage = "GAVE UP"
		statusColor = Color3.fromRGB(255, 100, 100) -- Red
	else
		statusMessage = winnerName:upper() .. " WINS!"
	end

	-- Entrance Animation
	React.useEffect(function()
		local backdrop = backdropRef.current
		local group = groupRef.current
		if not backdrop or not group then
			return
		end

		-- Reset states
		backdrop.BackgroundTransparency = 1

		-- Use a UIScale for pop-in effect
		local uiScale = group:FindFirstChildOfClass("UIScale")
		if not uiScale then
			uiScale = Instance.new("UIScale")
			uiScale.Parent = group
		end
		uiScale.Scale = 0.8

		-- Backdrop keep transparent
		TweenService:Create(backdrop, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1, -- Stay transparent to show global background
		}):Play()

		-- Panel Pop-in using UIScale
		TweenService:Create(uiScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1,
		}):Play()

		-- Play Lobby music when end screen appears
		SoundUtils.playLobbyMusic()
	end, {})

	return e("Frame", {
		ref = backdropRef,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1), -- White for gradient
		BackgroundTransparency = 1, -- Animated
		ZIndex = 100,
	}, {

		MainPanel = e("Frame", {
			ref = groupRef,
			Size = UDim2.fromScale(0.45, 0.75),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(20, 30, 60),
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

			Header = (page == "Results") and e("TextLabel", {
				Size = UDim2.fromScale(1, 0.12),
				BackgroundTransparency = 1,
				Text = "GAME OVER",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
			}, {
				UIStroke = e("UIStroke", {
					Color = Color3.fromRGB(249, 0, 149),
					Thickness = 3,
				}),
			}) or nil,

			WinnerSection = (page == "Results") and e("Frame", {
				Size = UDim2.fromScale(1, 0.25),
				Position = UDim2.fromScale(0, 0.15),
				BackgroundTransparency = 1,
			}, {
				WinnerText = e("TextLabel", {
					Size = UDim2.fromScale(1, 0.45),
					Position = UDim2.fromScale(0, 0),
					BackgroundTransparency = 1,
					Text = statusMessage,
					TextColor3 = statusColor,
					TextScaled = true,
					FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Normal),
				}, {
					UIStroke = e("UIStroke", {
						Color = Color3.new(0, 0, 0),
						Thickness = 2,
					}),
				}),
			}) or nil,

			ResultsList = (page == "Results")
					and e(
						"ScrollingFrame",
						{
							Size = UDim2.fromScale(1, 0.6),
							Position = UDim2.fromScale(0, 0.25),
							BackgroundTransparency = 1,
							AutomaticCanvasSize = Enum.AutomaticSize.Y,
							ScrollBarThickness = 0,
							ScrollingDirection = Enum.ScrollingDirection.Y,
							Active = true,
						},
						(function()
							local children = {
								UIListLayout = e("UIListLayout", {
									key = "ListLayout",
									SortOrder = Enum.SortOrder.LayoutOrder,
									Padding = UDim.new(0.03, 0),
								}),

								UIPadding = e("UIPadding", {
									key = "Padding",
									PaddingTop = UDim.new(0.01, 0),
									PaddingLeft = UDim.new(0.05, 0),
									PaddingRight = UDim.new(0.05, 0),
								}),
							}

							for i, res in ipairs(results) do
								local isWinner = i == 1
								local rankColor = if i == 1
									then Color3.fromRGB(255, 215, 0)
									elseif i == 2 then Color3.fromRGB(192, 192, 192)
									elseif i == 3 then Color3.fromRGB(205, 127, 50)
									else Color3.fromRGB(180, 180, 200)

								children["Result_" .. res.UserId] = e("Frame", {
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
											-- Use ID 1 for CPU players (negative IDs) so they have a valid avatar
											Image = "rbxthumb://type=AvatarHeadShot&id=" .. (if res.UserId < 0
												then 1
												else res.UserId) .. "&w=150&h=150",
										}, {
											UICorner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
										}),
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
									}),
								})
							end

							return children
						end)()
					)
				or e(
					"ScrollingFrame",
					{
						Size = UDim2.fromScale(1, 0.85),
						Position = UDim2.fromScale(0, 0),
						BackgroundTransparency = 1,
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						ScrollBarThickness = 0,
						ScrollingDirection = Enum.ScrollingDirection.Y,
						CanvasSize = UDim2.fromScale(0, 0),
						Active = true,
					},
					(function()
						local children = {
							UIListLayout = e("UIListLayout", {
								SortOrder = Enum.SortOrder.LayoutOrder,
								Padding = UDim.new(0.03, 0),
							}),
							UIPadding = e("UIPadding", {
								PaddingTop = UDim.new(0.01, 0),
								PaddingLeft = UDim.new(0.05, 0),
								PaddingRight = UDim.new(0.05, 0),
							}),
						}

						if myStats then
							for i, stat in ipairs(myStats) do
								children["Stat_" .. i] = e(StatRow, {
									index = i,
									label = stat.Label,
									value = stat.Value,
									icon = stat.Icon,
									color = stat.Color,
								})
							end
						end

						return children
					end)()
				),

			Actions = e("Frame", {
				Size = UDim2.fromScale(0.8, 0.11),
				Position = UDim2.fromScale(0.5, 0.98),
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
			}, {
				UIListLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0.05, 0),
				}),

				LeaveButton = e(TextButton, {
					Text = "Back to Menu",
					Variant = "secondary",
					Size = UDim2.fromScale(if page == "Results" then 0.45 else 1, 1),
					OnClick = function()
						if props.OnLeave then
							props.OnLeave()
						end
						ScrabbleServiceClient:leaveLobby()
					end,
				}),

				NextButton = (page == "Results") and e(TextButton, {
					Text = "Stats",
					Variant = "primary",
					Size = UDim2.fromScale(0.45, 1),
					OnClick = function()
						setPage("Stats")
					end,
				}) or nil,
			}),
		}),
	})
end
