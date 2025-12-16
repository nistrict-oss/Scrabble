--[[
	ScoreBoard.luau
	
	Displays all players' scores and indicates whose turn it is.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

export type PlayerScore = {
	UserId: number,
	Name: string,
	Score: number,
	IsCurrentTurn: boolean,
}

export type ScoreBoardProps = {
	Players: { PlayerScore },
	TilesRemaining: number?,
}

return function(props: ScoreBoardProps)
	local players = props.Players or {}
	local tilesRemaining = props.TilesRemaining or 0
	
	local entries = {}
	for i, player in ipairs(players) do
		entries["Player_" .. i] = e("Frame", {
			Size = UDim2.new(1, 0, 0, 50),
			BackgroundColor3 = if player.IsCurrentTurn 
				then Color3.fromRGB(249, 0, 149)
				else Color3.fromRGB(45, 70, 120),
			LayoutOrder = i,
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0.2, 0),
			}),
			
			UIStroke = e("UIStroke", {
				Color = Color3.new(1, 1, 1),
				Thickness = if player.IsCurrentTurn then 2 else 1,
				Transparency = if player.IsCurrentTurn then 0 else 0.5,
			}),
			
			UIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.1, 0),
				PaddingTop = UDim.new(0.1, 0),
				PaddingLeft = UDim.new(0.05, 0),
				PaddingRight = UDim.new(0.05, 0),
			}),
			
			-- Turn indicator
			TurnIndicator = player.IsCurrentTurn and e("Frame", {
				Size = UDim2.fromScale(0.08, 0.6),
				Position = UDim2.fromScale(0, 0.2),
				BackgroundColor3 = Color3.fromRGB(249, 0, 149), -- Pink accent
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0.5, 0),
				}),
			}) or nil,
			
			Name = e("TextLabel", {
				Size = UDim2.fromScale(0.6, 1),
				Position = UDim2.fromScale(0.1, 0),
				BackgroundTransparency = 1,
				Text = player.Name,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Font.new(
					"rbxassetid://11702779517",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
			}),
			
			Score = e("TextLabel", {
				Size = UDim2.fromScale(0.3, 1),
				Position = UDim2.fromScale(0.7, 0),
				BackgroundTransparency = 1,
				Text = tostring(player.Score),
				TextColor3 = Color3.fromRGB(249, 0, 149), -- Pink accent
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Right,
				FontFace = Font.new(
					"rbxassetid://11702779517",
					Enum.FontWeight.Heavy,
					Enum.FontStyle.Normal
				),
			}),
		})
	end
	
	entries["UIListLayout"] = e("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	})
	
	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(35, 55, 100),
		ClipsDescendants = true,
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
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			Text = "SCORES",
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			FontFace = Font.new(
				"rbxassetid://11702779517",
				Enum.FontWeight.Heavy,
				Enum.FontStyle.Italic
			),
		}),
		
		PlayerList = e("Frame", {
			Size = UDim2.new(1, 0, 1, -70),
			Position = UDim2.fromOffset(0, 35),
			BackgroundTransparency = 1,
		}, entries),
		
		TilesRemaining = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 25),
			Position = UDim2.new(0, 0, 1, -25),
			BackgroundTransparency = 1,
			Text = "Tiles in bag: " .. tilesRemaining,
			TextColor3 = Color3.fromRGB(150, 150, 180),
			TextScaled = true,
			FontFace = Font.new(
				"rbxassetid://11702779517",
				Enum.FontWeight.Medium,
				Enum.FontStyle.Normal
			),
		}),
	})
end

