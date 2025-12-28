--[[
	EliminationScreen.luau
	
	Shown to players who have been eliminated (ran out of time) but the game continues.
	Provides option to spectate or leave.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)
local AnimatedModal = require(ReplicatedStorage.UI.components.frames.AnimatedModal)
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local e = React.createElement

export type EliminationScreenProps = {
	GameState: any,
	OnSpectate: () -> (),
	OnViewStats: () -> (),
	OnLeave: () -> (),
	Visible: boolean?,
}

return function(props: EliminationScreenProps)
	local gameState = props.GameState
	local isVisible = props.Visible ~= false -- Default to true if not specified

	-- Get player's final score
	local myScore = 0
	if gameState and gameState.Scores then
		myScore = gameState.Scores[tostring(LocalPlayer.UserId)] or gameState.Scores[LocalPlayer.UserId] or 0
	end

	return e(AnimatedModal, {
		Visible = isVisible,
		Size = UDim2.fromScale(0.4, 0.45),
		ZIndex = 50,
		BackdropTransparency = 0.4,
	}, {
		Panel = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(40, 20, 30),
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0.05, 0) }),
			UIStroke = e("UIStroke", {
				Color = Color3.fromRGB(255, 80, 80),
				Thickness = 3,
			}),
			UIAspectRatioConstraint = e("UIAspectRatioConstraint", { AspectRatio = 1.2 }),
			UIPadding = e("UIPadding", {
				PaddingTop = UDim.new(0.05, 0),
				PaddingBottom = UDim.new(0.05, 0),
				PaddingLeft = UDim.new(0.08, 0),
				PaddingRight = UDim.new(0.08, 0),
			}),

			Header = e("TextLabel", {
				Size = UDim2.fromScale(1, 0.2),
				Position = UDim2.fromScale(0, 0),
				BackgroundTransparency = 1,
				Text = "ELIMINATED",
				TextColor3 = Color3.fromRGB(255, 80, 80),
				TextScaled = true,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
			}, {
				UIStroke = e("UIStroke", {
					Color = Color3.new(0, 0, 0),
					Thickness = 2,
				}),
			}),

			Message = e("TextLabel", {
				Size = UDim2.fromScale(1, 0.15),
				Position = UDim2.fromScale(0, 0.22),
				BackgroundTransparency = 1,
				Text = "You ran out of time!",
				TextColor3 = Color3.fromRGB(200, 200, 220),
				TextScaled = true,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium),
			}),

			ScoreSection = e("Frame", {
				Size = UDim2.fromScale(1, 0.2),
				Position = UDim2.fromScale(0, 0.4),
				BackgroundTransparency = 1,
			}, {
				Label = e("TextLabel", {
					Size = UDim2.fromScale(0.5, 1),
					BackgroundTransparency = 1,
					Text = "Final Score:",
					TextColor3 = Color3.fromRGB(180, 180, 200),
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
				}),
				Value = e("TextLabel", {
					Size = UDim2.fromScale(0.5, 1),
					Position = UDim2.fromScale(0.5, 0),
					BackgroundTransparency = 1,
					Text = tostring(myScore),
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Right,
					FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy),
				}),
			}),

			Actions = e("Frame", {
				Size = UDim2.fromScale(1, 0.22),
				Position = UDim2.fromScale(0, 0.75),
				BackgroundTransparency = 1,
			}, {
				UIListLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0.05, 0),
				}),

				SpectateButton = e(TextButton, {
					Text = "Spectate",
					Variant = "primary",
					Size = UDim2.fromScale(0.45, 1),
					OnClick = props.OnSpectate,
				}),

				ViewStatsButton = e(TextButton, {
					Text = "Leave",
					Variant = "secondary",
					Size = UDim2.fromScale(0.45, 1),
					OnClick = function()
						-- Show stats/end screen first, then player can leave from there
						if props.OnViewStats then
							props.OnViewStats()
						end
					end,
				}),
			}),
		}),
	})
end
