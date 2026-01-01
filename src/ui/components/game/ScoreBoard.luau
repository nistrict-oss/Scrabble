--[[
	ScoreBoard.luau
	
	Displays all players' scores and indicates whose turn it is.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.React)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)
local GameConstants = require(ReplicatedStorage.Shared.Modules.Core.GameConstants)
local InGameVolumeSlider = require(ReplicatedStorage.UI.components.game.InGameVolumeSlider)

local e = React.createElement

export type PlayerScore = {
	UserId: number,
	Name: string,
	Score: number,
	IsCurrentTurn: boolean,
	TimeRemaining: number?, -- seconds
	IsEliminated: boolean?, -- player is eliminated but still shown
}

export type ScoreBoardProps = {
	Players: { PlayerScore },
	TilesRemaining: number?,
	ListRef: any?,
	Settings: { StarDoublesPoints: boolean? }?,
	OnReportPosition: (userId: number, pos: Vector2) -> (),
	OnLeave: (() -> ())?,
	LocalUserId: number,
}

local function ScoreEntry(props: {
	Player: PlayerScore,
	LayoutOrder: number,
	OnReportPosition: (number, Vector2) -> (),
	OnLeave: (() -> ())?,
	IsLocal: boolean,
})
	local player = props.Player
	local prevScore = React.useRef(player.Score)
	local scaleRef = React.useRef(nil :: UIScale?)
	local frameRef = React.useRef(nil :: Frame?)
	local isEliminated = player.IsEliminated == true
	local isCPU = player.UserId < 0 -- CPU players have negative IDs

	-- Thinking animation state for CPU players (cycling dots: 0-3)
	local dotCount, setDotCount = React.useState(0)
	local thinkingText = "Thinking" .. string.rep(".", dotCount)

	-- Cycle dots when CPU is thinking (only when it's their turn)
	React.useEffect(function()
		if not isCPU or not player.IsCurrentTurn or isEliminated then
			return
		end
		local connection
		connection = game:GetService("RunService").Heartbeat:Connect(function()
			-- Cycle every ~400ms (4 stages: 0, 1, 2, 3 dots)
			local dots = math.floor(os.clock() * 2.5) % 4
			if dots ~= dotCount then
				setDotCount(dots)
			end
		end)
		return function()
			if connection then
				connection:Disconnect()
			end
		end
	end, { isCPU, player.IsCurrentTurn, isEliminated })

	local function reportPosition()
		local frame = frameRef.current
		if frame and props.OnReportPosition then
			-- Target slightly lower than center (0.75 Y) to fix "too high" visual
			props.OnReportPosition(player.UserId, frame.AbsolutePosition + frame.AbsoluteSize * Vector2.new(0.5, 0.75))
		end
	end

	React.useEffect(function()
		reportPosition()
	end, { player.UserId })

	React.useEffect(function()
		if player.Score ~= prevScore.current then
			prevScore.current = player.Score
			if scaleRef.current then
				scaleRef.current.Scale = 1.4
				TweenService
					:Create(scaleRef.current, TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
						Scale = 1,
					})
					:Play()
			end
		end
	end, { player.Score })

	-- Determine colors based on state
	local bgColor = if isEliminated
		then Color3.fromRGB(60, 60, 70) -- Grey for eliminated
		elseif player.IsCurrentTurn then Color3.fromRGB(255, 45, 150)
		else Color3.fromRGB(40, 60, 110)

	local textColor = if isEliminated
		then Color3.fromRGB(120, 120, 130) -- Muted grey text
		else Color3.new(1, 1, 1)

	local scoreColor = if isEliminated
		then Color3.fromRGB(100, 100, 110)
		elseif player.IsCurrentTurn then Color3.new(1, 1, 1)
		else Color3.fromRGB(249, 0, 149)

	return e("Frame", {
		ref = frameRef,
		[React.Change.AbsolutePosition] = reportPosition,
		Size = UDim2.new(1, 0, 0, 50), -- Fixed height of 50px per entry
		BackgroundColor3 = bgColor,
		LayoutOrder = props.LayoutOrder,
	}, {
		UIScale = e("UIScale", { ref = scaleRef }),

		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),

		UIStroke = e("UIStroke", {
			Color = if isEliminated then Color3.fromRGB(80, 80, 90) else Color3.new(1, 1, 1),
			Thickness = if player.IsCurrentTurn and not isEliminated then 2 else 1,
			Transparency = if isEliminated then 0.7 elseif player.IsCurrentTurn then 0 else 0.5,
		}),

		UIPadding = e("UIPadding", {
			PaddingBottom = UDim.new(0, 4),
			PaddingTop = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
		}),

		Avatar = e("ImageLabel", {
			Size = UDim2.fromScale(0.15, 0.85),
			Position = UDim2.fromScale(0.01, 0.5),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			-- Use ID 1 for CPU players (negative IDs) so they have a valid avatar
			Image = "rbxthumb://type=AvatarHeadShot&id="
				.. (if player.UserId < 0 then 1 else player.UserId)
				.. "&w=150&h=150",
			ImageTransparency = if isEliminated then 0.5 else 0,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
			UIAspectRatioConstraint = e("UIAspectRatioConstraint", { AspectRatio = 1 }),
			UIStroke = e("UIStroke", {
				Color = if isEliminated then Color3.fromRGB(80, 80, 90) else Color3.new(1, 1, 1),
				Thickness = 2,
				Transparency = if isEliminated then 0.5 else 0,
			}),
		}),

		Name = e("TextLabel", {
			Size = UDim2.fromScale(0.5, if (player.TimeRemaining or isCPU) and not isEliminated then 0.5 else 1),
			Position = UDim2.fromScale(0.18, 0),
			BackgroundTransparency = 1,
			Text = player.Name .. (if isEliminated then " (OUT)" else ""),
			TextColor3 = textColor,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		}),

		-- Timer for human players, "Thinking..." for CPU players on their turn
		TimeRemaining = (function()
			-- CPU with current turn: show thinking animation
			if isCPU and player.IsCurrentTurn and not isEliminated then
				return e("TextLabel", {
					Size = UDim2.fromScale(0.4, 0.4),
					Position = UDim2.fromScale(0.18, 0.55),
					BackgroundTransparency = 1,
					Text = thinkingText,
					TextColor3 = Color3.fromRGB(200, 200, 220),
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium, Enum.FontStyle.Italic),
				})
			-- Human player with time remaining
			elseif player.TimeRemaining and not isEliminated then
				return e("TextLabel", {
					Size = UDim2.fromScale(0.4, 0.4),
					Position = UDim2.fromScale(0.18, 0.55),
					BackgroundTransparency = 1,
					Text = if player.TimeRemaining >= 3600
						then string.format(
							"%d:%02d:%02d",
							math.floor(player.TimeRemaining / 3600),
							math.floor((player.TimeRemaining % 3600) / 60),
							player.TimeRemaining % 60
						)
						else string.format(
							"%d:%02d",
							math.floor(player.TimeRemaining / 60),
							player.TimeRemaining % 60
						),
					TextColor3 = if player.IsCurrentTurn then Color3.new(1, 1, 1) else Color3.fromRGB(200, 200, 220),
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				})
			end
			return nil
		end)(),

		Score = e("TextLabel", {
			Size = UDim2.fromScale(0.2, 1),
			Position = UDim2.fromScale(0.78, 0),
			BackgroundTransparency = 1,
			Text = tostring(player.Score),
			TextColor3 = scoreColor,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Right,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Normal),
		}),

		LeaveButton = props.IsLocal and props.OnLeave and not isEliminated and e(TextButton, {
			Text = "X",
			Variant = "danger",
			Size = UDim2.fromScale(0.1, 0.6),
			Position = UDim2.fromScale(0.98, 0.5),
			AnchorPoint = Vector2.new(1, 0.5),
			CornerRadius = UDim.new(0.5, 0),
			OnClick = props.OnLeave,
		}) or nil,
	})
end

return function(props: ScoreBoardProps)
	local players = props.Players or {}
	local tilesRemaining = props.TilesRemaining or 0

	local entries = {}
	for i = 1, math.min(#players, 10) do
		local player = players[i]
		table.insert(
			entries,
			e(ScoreEntry, {
				key = "Player_" .. tostring(player.UserId),
				Player = player,
				LayoutOrder = i,
				OnReportPosition = props.OnReportPosition,
				OnLeave = props.OnLeave,
				IsLocal = player.UserId == props.LocalUserId,
			})
		)
	end

	table.insert(
		entries,
		e("UIListLayout", {
			key = "UIListLayout",
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0.01, 0),
		})
	)

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1), -- White for gradient
	}, {
		UIGradient = e("UIGradient", {
			Color = ColorSequence.new(GameConstants.Gradients.frame),
			Rotation = 90,
		}),
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 12),
		}),

		UIStroke = e("UIStroke", {
			Color = Color3.new(1, 1, 1),
			Thickness = 2,
		}),

		UIPadding = e("UIPadding", {
			PaddingBottom = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),

		Header = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 40),
			Position = UDim2.new(0, 0, 0, 15),
			BackgroundTransparency = 1,
			Text = if props.Settings and props.Settings.StarDoublesPoints == false then "SCORES" else "SCORES (★ 2X)",
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
		}),

		PlayerList = e(
			"ScrollingFrame",
			{
				Size = UDim2.new(1, 0, 1, -100), -- Leave room for header, volume slider, and tiles remaining
				Position = UDim2.new(0, 0, 0, 65),
				BackgroundTransparency = 1,
				ScrollBarThickness = 4,
				ScrollBarImageColor3 = Color3.fromRGB(200, 200, 220),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				ref = props.ListRef,
			},
			entries,
			{
				UIPadding = e("UIPadding", {
					PaddingBottom = UDim.new(0, 4),
					PaddingTop = UDim.new(0, 4),
					PaddingLeft = UDim.new(0, 4),
					PaddingRight = UDim.new(0, 4),
				}),
			}
		),

		-- Volume slider above tiles remaining
		VolumeSliderContainer = e("Frame", {
			Size = UDim2.new(1, 0, 0, 36),
			Position = UDim2.new(0, 0, 1, -58),
			BackgroundTransparency = 1,
		}, {
			Slider = e(InGameVolumeSlider),
		}),

		TilesRemaining = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 18),
			Position = UDim2.new(0, 0, 1, -18),
			BackgroundTransparency = 1,
			Text = "Tiles in bag: " .. tilesRemaining,
			TextColor3 = Color3.fromRGB(150, 150, 180),
			TextScaled = true,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
		}),
	})
end
