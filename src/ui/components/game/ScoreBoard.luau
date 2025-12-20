--[[
	ScoreBoard.luau
	
	Displays all players' scores and indicates whose turn it is.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

export type PlayerScore = {
	UserId: number,
	Name: string,
	Score: number,
	IsCurrentTurn: boolean,
	TimeRemaining: number?, -- seconds
}

export type ScoreBoardProps = {
	Players: { PlayerScore },
	TilesRemaining: number?,
	ListRef: any?,
	OnReportPosition: (userId: number, pos: Vector2) -> (),
}

local function ScoreEntry(
	props: { Player: PlayerScore, LayoutOrder: number, OnReportPosition: (number, Vector2) -> () }
)
	local player = props.Player
	local prevScore = React.useRef(player.Score)
	local scaleRef = React.useRef(nil :: UIScale?)
	local frameRef = React.useRef(nil :: Frame?)

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

	return e("Frame", {
		ref = frameRef,
		[React.Change.AbsolutePosition] = reportPosition,
		Size = UDim2.fromScale(1, 0.5),
		BackgroundColor3 = if player.IsCurrentTurn then Color3.fromRGB(249, 0, 149) else Color3.fromRGB(45, 70, 120),
		LayoutOrder = props.LayoutOrder,
	}, {
		UIScale = e("UIScale", { ref = scaleRef }),

		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0.2, 0),
		}),

		UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
			AspectRatio = 5.6,
		}),

		UIStroke = e("UIStroke", {
			Color = Color3.new(1, 1, 1),
			Thickness = if player.IsCurrentTurn then 2 else 1,
			Transparency = if player.IsCurrentTurn then 0 else 0.5,
		}),

		UIPadding = e("UIPadding", {
			PaddingBottom = UDim.new(0.1, 0),
			PaddingTop = UDim.new(0.1, 0),
			PaddingLeft = UDim.new(0.03, 0),
			PaddingRight = UDim.new(0.03, 0),
		}),

		Avatar = e("ImageLabel", {
			Size = UDim2.fromScale(0.12, 0.8),
			Position = UDim2.fromScale(0.01, 0.1),
			BackgroundTransparency = 1,
			Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150",
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
			UIStroke = e("UIStroke", {
				Color = Color3.new(1, 1, 1),
				Thickness = 2,
			}),
		}),

		Name = e("TextLabel", {
			Size = UDim2.fromScale(0.5, if player.TimeRemaining then 0.5 else 1),
			Position = UDim2.fromScale(0.17, 0),
			BackgroundTransparency = 1,
			Text = player.Name,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		}),

		TimeRemaining = player.TimeRemaining and e("TextLabel", {
			Size = UDim2.fromScale(0.4, 0.35),
			Position = UDim2.fromScale(0.22, 0.55),
			BackgroundTransparency = 1,
			Text = if player.TimeRemaining >= 3600
				then string.format(
					"%d:%02d:%02d",
					math.floor(player.TimeRemaining / 3600),
					math.floor((player.TimeRemaining % 3600) / 60),
					player.TimeRemaining % 60
				)
				else string.format("%d:%02d", math.floor(player.TimeRemaining / 60), player.TimeRemaining % 60),
			TextColor3 = if player.IsCurrentTurn then Color3.new(1, 1, 1) else Color3.fromRGB(200, 200, 220),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
		}) or nil,

		Score = e("TextLabel", {
			Size = UDim2.fromScale(0.25, 1),
			Position = UDim2.fromScale(0.75, 0),
			BackgroundTransparency = 1,
			Text = tostring(player.Score),
			TextColor3 = if player.IsCurrentTurn then Color3.new(1, 1, 1) else Color3.fromRGB(249, 0, 149),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Right,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Normal),
		}),
	})
end

return function(props: ScoreBoardProps)
	local players = props.Players or {}
	local tilesRemaining = props.TilesRemaining or 0

	local entries = {}
	for i = 1, math.min(#players, 10) do
		local player = players[i]
		entries["Player_" .. player.UserId] = e(ScoreEntry, {
			Player = player,
			LayoutOrder = i,
			OnReportPosition = props.OnReportPosition,
		})
	end

	entries["UIListLayout"] = e("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	})

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(30, 45, 90), -- Match GameBoard
	}, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0.05, 0),
		}),

		UIStroke = e("UIStroke", {
			Color = Color3.new(1, 1, 1),
			Thickness = 2,
		}),

		UIPadding = e("UIPadding", {
			PaddingBottom = UDim.new(0.03, 0),
			PaddingTop = UDim.new(0.03, 0),
			PaddingLeft = UDim.new(0.05, 0),
			PaddingRight = UDim.new(0.05, 0),
		}),

		Header = e("TextLabel", {
			Size = UDim2.fromScale(1, 0.05),
			BackgroundTransparency = 1,
			Text = "SCORES",
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
		}),

		PlayerList = e(
			"Frame",
			{
				Size = UDim2.fromScale(1, 0.9), -- Take up most of the space
				Position = UDim2.fromOffset(0, 35),
				BackgroundTransparency = 1,
				ref = props.ListRef,
			},
			entries,
			{
				UIPadding = e("UIPadding", {
					PaddingBottom = UDim.new(0.03, 0),
					PaddingTop = UDim.new(0.03, 0),
					PaddingLeft = UDim.new(0.05, 0),
					PaddingRight = UDim.new(0.05, 0),
				}),
			}
		),

		TilesRemaining = e("TextLabel", {
			Size = UDim2.fromScale(1, 0.05),
			Position = UDim2.fromScale(0, 0.96),
			BackgroundTransparency = 1,
			Text = "Tiles in bag: " .. tilesRemaining,
			TextColor3 = Color3.fromRGB(150, 150, 180),
			TextScaled = true,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
		}),
	})
end
