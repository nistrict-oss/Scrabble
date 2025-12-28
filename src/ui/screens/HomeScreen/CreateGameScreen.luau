local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local StyledPanel = require(ReplicatedStorage.UI.components.frames.StyledPanel)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)
local SettingToggle = require(ReplicatedStorage.UI.components.settings.SettingToggle)
local ScrabbleServiceClient = require(ReplicatedStorage.Shared.Services.ScrabbleService.ScrabbleServiceClient)
local AnimatedModal = require(ReplicatedStorage.UI.components.frames.AnimatedModal)

local e = React.createElement

local CPU_DIFFICULTIES = { "Easy", "Medium", "Hard", "Impossible" }

return function(props)
	-- Form state
	local lobbyName, setLobbyName = React.useState("New Game")
	local maxPlayers, setMaxPlayers = React.useState(1)
	local isPrivate, setIsPrivate = React.useState(false)
	local timerSeconds, setTimerSeconds = React.useState(0)
	local starDoublesPoints, setStarDoublesPoints = React.useState(true)
	local cpuCount, setCpuCount = React.useState(1)
	local cpuDifficultyIndex, setCpuDifficultyIndex = React.useState(1) -- Default to Easy

	-- Calculate max CPU count: 10 - maxPlayers (9 for solo, down to 0 for 10 players)
	local maxCpuCount = 10 - maxPlayers

	-- Calculate min CPU count: 1 if solo (maxPlayers == 1), else 0
	local minCpuCount = if maxPlayers == 1 then 1 else 0

	-- Clamp cpuCount based on maxPlayers
	React.useEffect(function()
		if cpuCount > maxCpuCount then
			setCpuCount(maxCpuCount)
		elseif cpuCount < minCpuCount then
			setCpuCount(minCpuCount)
		end
	end, { maxPlayers, cpuCount, maxCpuCount, minCpuCount })

	-- Visibility state for animation
	local isVisible = props.Visible ~= false -- Default to true if not specified

	return e(AnimatedModal, {
		Visible = isVisible,
		OnClose = props.OnClose,
		Size = UDim2.fromScale(0.55, 0.85),
		ZIndex = 100,
	}, {

		-- Main Content Panel
		Panel = e(StyledPanel, {
			ZIndex = 3,
			AspectRatio = 1,
			Children = {
				-- Header
				header = e("Frame", {
					BackgroundColor3 = Color3.new(1, 1, 1),
					Position = UDim2.fromScale(0.015625, 0.0331126),
					Size = UDim2.fromScale(0.96875, 0.1193377),
				}, {
					uICorner = e("UICorner", { CornerRadius = UDim.new(0.133333, 0) }),
					uIGradient = e("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromRGB(47, 52, 88)),
							ColorSequenceKeypoint.new(0.89, Color3.fromRGB(47, 52, 88)),
							ColorSequenceKeypoint.new(0.91, Color3.fromRGB(43, 46, 80)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(43, 46, 80)),
						}),
						Rotation = 90,
					}),
					uIStroke = e("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }),

					title = e("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
						Size = UDim2.fromScale(1, 1),
						Text = "Create New Game",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
					}, {
						uIPadding = e("UIPadding", { PaddingBottom = UDim.new(0.2, 0), PaddingTop = UDim.new(0.2, 0) }),
					}),
				}),

				-- Content Body
				content = e("Frame", {
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.015625, 0.165563),
					Size = UDim2.fromScale(0.96875, 0.6),
					ZIndex = 2,
				}, {
					uIListLayout = e("UIListLayout", {
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						Padding = UDim.new(0.01),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					uIPadding = e("UIPadding", {
						PaddingTop = UDim.new(0.01, 0),
						PaddingBottom = UDim.new(0.01, 0),
					}),

					-- LOBBY NAME
					NameInput = e("Frame", {
						Size = UDim2.fromScale(0.9, 0.15),
						BackgroundTransparency = 1,
						LayoutOrder = 1,
					}, {
						Label = e("TextLabel", {
							Size = UDim2.fromScale(0.3, 1),
							BackgroundTransparency = 1,
							Text = "Game Name:",
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							TextXAlignment = Enum.TextXAlignment.Left,
							FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
						}),
						Input = e("TextBox", {
							Size = UDim2.fromScale(0.65, 0.8),
							Position = UDim2.fromScale(0.35, 0.1),
							BackgroundColor3 = Color3.fromRGB(50, 75, 130),
							Text = lobbyName,
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							PlaceholderText = "Enter Name...",
							[React.Event.Changed] = function(rbx)
								setLobbyName(rbx.Text)
							end,
						}, {
							UICorner = e("UICorner", { CornerRadius = UDim.new(0.2, 0) }),
							UIPadding = e("UIPadding", { PaddingLeft = UDim.new(0.05, 0) }),
						}),
					}),

					-- MAX PLAYERS
					MaxPlayers = e("Frame", {
						Size = UDim2.fromScale(0.9, 0.15),
						BackgroundTransparency = 1,
						LayoutOrder = 2,
					}, {
						Label = e("TextLabel", {
							Size = UDim2.fromScale(0.3, 1),
							BackgroundTransparency = 1,
							Text = "Max Players:",
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							TextXAlignment = Enum.TextXAlignment.Left,
							FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
						}),
						Minus = e(TextButton, {
							Text = "-",
							Variant = "secondary",
							Size = UDim2.fromScale(0.1, 0.8),
							Position = UDim2.fromScale(0.35, 0.1),
							OnClick = function()
								setMaxPlayers(math.max(1, maxPlayers - 1))
							end,
						}),
						Value = e("TextLabel", {
							Size = UDim2.fromScale(0.2, 1),
							Position = UDim2.fromScale(0.48, 0),
							BackgroundTransparency = 1,
							Text = tostring(maxPlayers),
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
						}),
						Plus = e(TextButton, {
							Text = "+",
							Variant = "secondary",
							Size = UDim2.fromScale(0.1, 0.8),
							Position = UDim2.fromScale(0.7, 0.1),
							OnClick = function()
								setMaxPlayers(math.min(10, maxPlayers + 1))
							end,
						}),
					}),

					-- TIMER
					Timer = e("Frame", {
						Size = UDim2.fromScale(0.9, 0.15),
						BackgroundTransparency = 1,
						LayoutOrder = 5,
					}, {
						Label = e("TextLabel", {
							Size = UDim2.fromScale(0.3, 1),
							BackgroundTransparency = 1,
							Text = "Turn Timer:",
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							TextXAlignment = Enum.TextXAlignment.Left,
							FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
						}),
						Minus = e(TextButton, {
							Text = "-",
							Variant = "secondary",
							Size = UDim2.fromScale(0.1, 0.8),
							Position = UDim2.fromScale(0.35, 0.1),
							OnClick = function()
								if timerSeconds == 0 then
									setTimerSeconds(1200)
								elseif timerSeconds == 60 then
									setTimerSeconds(0)
								elseif timerSeconds > 60 then
									setTimerSeconds(timerSeconds - 30)
								end
							end,
						}),
						Value = e("TextLabel", {
							Size = UDim2.fromScale(0.23, 1),
							Position = UDim2.fromScale(0.465, 0),
							BackgroundTransparency = 1,
							Text = timerSeconds == 0 and "Inf"
								or (math.floor(timerSeconds / 60) .. "m " .. (timerSeconds % 60) .. "s"),
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
						}),
						Plus = e(TextButton, {
							Text = "+",
							Variant = "secondary",
							Size = UDim2.fromScale(0.1, 0.8),
							Position = UDim2.fromScale(0.7, 0.1),
							OnClick = function()
								if timerSeconds == 0 then
									setTimerSeconds(60)
								elseif timerSeconds == 1200 then
									setTimerSeconds(0)
								elseif timerSeconds < 1200 then
									setTimerSeconds(timerSeconds + 30)
								end
							end,
						}),
					}),

					-- CPU COUNT
					CPUCount = e("Frame", {
						Size = UDim2.fromScale(0.9, 0.15),
						BackgroundTransparency = 1,
						LayoutOrder = 3,
					}, {
						Label = e("TextLabel", {
							Size = UDim2.fromScale(0.3, 1),
							BackgroundTransparency = 1,
							Text = "CPU Players:",
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							TextXAlignment = Enum.TextXAlignment.Left,
							FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
						}),
						Minus = e(TextButton, {
							Text = "-",
							Variant = "secondary",
							Size = UDim2.fromScale(0.1, 0.8),
							Position = UDim2.fromScale(0.35, 0.1),
							OnClick = function()
								setCpuCount(math.max(minCpuCount, cpuCount - 1))
							end,
						}),
						Value = e("TextLabel", {
							Size = UDim2.fromScale(0.2, 1),
							Position = UDim2.fromScale(0.48, 0),
							BackgroundTransparency = 1,
							Text = tostring(cpuCount),
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
						}),
						Plus = e(TextButton, {
							Text = "+",
							Variant = "secondary",
							Size = UDim2.fromScale(0.1, 0.8),
							Position = UDim2.fromScale(0.7, 0.1),
							OnClick = function()
								setCpuCount(math.min(maxCpuCount, cpuCount + 1))
							end,
						}),
					}),

					-- CPU DIFFICULTY (only show if cpuCount > 0)
					CPUDifficulty = cpuCount > 0 and e("Frame", {
						Size = UDim2.fromScale(0.9, 0.15),
						BackgroundTransparency = 1,
						LayoutOrder = 4,
					}, {
						Label = e("TextLabel", {
							Size = UDim2.fromScale(0.3, 1),
							BackgroundTransparency = 1,
							Text = "CPU Difficulty:",
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							TextXAlignment = Enum.TextXAlignment.Left,
							FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
						}),
						Minus = e(TextButton, {
							Text = "<",
							Variant = "secondary",
							Size = UDim2.fromScale(0.1, 0.8),
							Position = UDim2.fromScale(0.35, 0.1),
							OnClick = function()
								local newIndex = cpuDifficultyIndex - 1
								if newIndex < 1 then
									newIndex = #CPU_DIFFICULTIES
								end
								setCpuDifficultyIndex(newIndex)
							end,
						}),
						Value = e("TextLabel", {
							Size = UDim2.fromScale(0.2, 1),
							Position = UDim2.fromScale(0.48, 0),
							BackgroundTransparency = 1,
							Text = CPU_DIFFICULTIES[cpuDifficultyIndex],
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
						}),
						Plus = e(TextButton, {
							Text = ">",
							Variant = "secondary",
							Size = UDim2.fromScale(0.1, 0.8),
							Position = UDim2.fromScale(0.7, 0.1),
							OnClick = function()
								local newIndex = cpuDifficultyIndex + 1
								if newIndex > #CPU_DIFFICULTIES then
									newIndex = 1
								end
								setCpuDifficultyIndex(newIndex)
							end,
						}),
					}) or nil,

					-- SETTINGS TOGGLES
					PrivateToggle = e(SettingToggle, {
						Name = "Private Lobby",
						Value = isPrivate,
						LayoutOrder = 6,
						OnChange = setIsPrivate,
					}),

					StarToggle = e(SettingToggle, {
						Name = "Star Doubles Points",
						Value = starDoublesPoints,
						LayoutOrder = 7,
						OnChange = setStarDoublesPoints,
					}),
				}),

				-- Footer Buttons
				footer = e("Frame", {
					Size = UDim2.fromScale(1, 0.15),
					Position = UDim2.fromScale(0, 0.85),
					BackgroundTransparency = 1,
					ZIndex = 5,
				}, {
					Cancel = e(TextButton, {
						Text = "Cancel",
						Variant = "secondary",
						Size = UDim2.fromScale(0.3, 0.7),
						Position = UDim2.fromScale(0.15, 0.15),
						OnClick = function()
							if props.OnClose then
								props.OnClose()
							end
						end,
					}),
					Create = e(TextButton, {
						Text = "Create",
						Variant = "primary",
						Size = UDim2.fromScale(0.3, 0.7),
						Position = UDim2.fromScale(0.55, 0.15),
						OnClick = function()
							ScrabbleServiceClient:createLobby(lobbyName, maxPlayers, isPrivate, nil, timerSeconds, {
								StarDoublesPoints = starDoublesPoints,
								CpuCount = cpuCount,
								CpuDifficulty = CPU_DIFFICULTIES[cpuDifficultyIndex],
							})
							if props.OnClose then
								props.OnClose()
							end
						end,
					}),
				}),
			},
		}),
	})
end
