local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local LeaderboardEntry = require(ReplicatedStorage.UI.components.cards.LeaderboardEntry)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)

local e = React.createElement

return function(_props)
	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.0963542, 0.212037),
		Size = UDim2.fromScale(0.808333, 0.713889),
		ZIndex = 0,
	}, {
		babyBoard = React.createElement("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			Position = UDim2.fromScale(0, 0.136187),
			Size = UDim2.fromScale(0.489691, 0.863813),
			ZIndex = 0,
		}, {
			uICorner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0.03003, 0),
			}),

			uIGradient = React.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 99, 174)),
					ColorSequenceKeypoint.new(0.97, Color3.fromRGB(90, 99, 174)),
					ColorSequenceKeypoint.new(0.98, Color3.fromRGB(81, 88, 156)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(81, 88, 156)),
				}),
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
													NumberSequenceKeypoint.new(0.97, 0),
													NumberSequenceKeypoint.new(0.98, 0),
													NumberSequenceKeypoint.new(1, 0),
				}),
			}),

			uIStroke = React.createElement("UIStroke", {
				Color = Color3.new(1, 1, 1),
				Thickness = 5,
			}),

			users = React.createElement("ScrollingFrame", {
				AutomaticCanvasSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				CanvasSize = UDim2.fromScale(0.364583, 0.462963),
				Position = UDim2.fromScale(0.0394737, 0.204204),
				ScrollBarThickness = 0,
				Size = UDim2.fromScale(0.921053, 0.750751),
				ZIndex = 0,
			}, {
				user = e(LeaderboardEntry, { Username = "Username", Wins = 10000, LayoutOrder = 1 }),
				user2 = e(LeaderboardEntry, { Username = "Username", Wins = 10000, LayoutOrder = 2 }),
				user3 = e(LeaderboardEntry, { Username = "Username", Wins = 10000, LayoutOrder = 3 }),
				user4 = e(LeaderboardEntry, { Username = "Username", Wins = 10000, LayoutOrder = 4 }),
				user5 = e(LeaderboardEntry, { Username = "Username", Wins = 10000, LayoutOrder = 5 }),
				user6 = e(LeaderboardEntry, { Username = "Username", Wins = 10000, LayoutOrder = 6 }),
				user7 = e(LeaderboardEntry, { Username = "Username", Wins = 10000, LayoutOrder = 7 }),
				user8 = e(LeaderboardEntry, { Username = "Username", Wins = 10000, LayoutOrder = 8 }),

				uIListLayout = React.createElement("UIListLayout", {
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0.02, 0),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			}),

			baby = React.createElement("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				Position = UDim2.fromScale(0.0394737, 0.0435435),
				Size = UDim2.fromScale(0.921053, 0.112613),
			}, {
				uICorner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0.133333, 0),
				}),

				uIGradient = React.createElement("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(47, 52, 88)),
						ColorSequenceKeypoint.new(0.89, Color3.fromRGB(47, 52, 88)),
						ColorSequenceKeypoint.new(0.91, Color3.fromRGB(43, 46, 80)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(43, 46, 80)),
					}),
					Rotation = 90,
					Transparency = NumberSequence.new({
																					NumberSequenceKeypoint.new(0, 0),
																					NumberSequenceKeypoint.new(0.89, 0),
																					NumberSequenceKeypoint.new(0.91, 0),
																					NumberSequenceKeypoint.new(1, 0),
					}),
				}),

				uIStroke = React.createElement("UIStroke", {
					Color = Color3.new(1, 1, 1),
					Thickness = 2,
				}),

				background = React.createElement("ImageLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(-0.0142857, -0.133333),
					Size = UDim2.fromScale(1.02857, 1.26667),
					ZIndex = 0,
				}),

				textLabel = React.createElement("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = Font.new(
						"rbxassetid://11702779517",
						Enum.FontWeight.Heavy,
						Enum.FontStyle.Italic
					),
					RichText = true,
					Size = UDim2.fromScale(1, 1),
					Text = "Baby",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
				}, {
					uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
						AspectRatio = 9.33333,
					}),

					uIPadding = React.createElement("UIPadding", {
						PaddingBottom = UDim.new(0.26, 0),
						PaddingTop = UDim.new(0.26, 0),
					}),
				}),
			}),
		}),

		parentBoard = React.createElement("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			Position = UDim2.fromScale(0.510309, 0.136187),
			Size = UDim2.fromScale(0.489691, 0.863813),
			ZIndex = 0,
		}, {
			uICorner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0.03003, 0),
			}),

			uIGradient = React.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 99, 174)),
					ColorSequenceKeypoint.new(0.97, Color3.fromRGB(90, 99, 174)),
					ColorSequenceKeypoint.new(0.98, Color3.fromRGB(81, 88, 156)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(81, 88, 156)),
				}),
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
													NumberSequenceKeypoint.new(0.97, 0),
													NumberSequenceKeypoint.new(0.98, 0),
													NumberSequenceKeypoint.new(1, 0),
				}),
			}),

			uIStroke = React.createElement("UIStroke", {
				Color = Color3.new(1, 1, 1),
				Thickness = 5,
			}),

			parent = React.createElement("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				Position = UDim2.fromScale(0.0394737, 0.0435435),
				Size = UDim2.fromScale(0.921053, 0.112613),
			}, {
				uICorner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0.133333, 0),
				}),

				uIGradient = React.createElement("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(47, 52, 88)),
						ColorSequenceKeypoint.new(0.89, Color3.fromRGB(47, 52, 88)),
						ColorSequenceKeypoint.new(0.91, Color3.fromRGB(43, 46, 80)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(43, 46, 80)),
					}),
					Rotation = 90,
					Transparency = NumberSequence.new({
																					NumberSequenceKeypoint.new(0, 0),
																					NumberSequenceKeypoint.new(0.89, 0),
																					NumberSequenceKeypoint.new(0.91, 0),
																					NumberSequenceKeypoint.new(1, 0),
					}),
				}),

				uIStroke = React.createElement("UIStroke", {
					Color = Color3.new(1, 1, 1),
					Thickness = 2,
				}),

				background = React.createElement("ImageLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(-0.0142857, -0.133333),
					Size = UDim2.fromScale(1.02857, 1.26667),
					ZIndex = 0,
				}),

				textLabel = React.createElement("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = Font.new(
						"rbxassetid://11702779517",
						Enum.FontWeight.Heavy,
						Enum.FontStyle.Italic
					),
					RichText = true,
					Size = UDim2.fromScale(1, 1),
					Text = "Parent",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
				}, {
					uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
						AspectRatio = 9.33333,
					}),

					uIPadding = React.createElement("UIPadding", {
						PaddingBottom = UDim.new(0.26, 0),
						PaddingTop = UDim.new(0.26, 0),
					}),
				}),
			}),

			users = React.createElement("ScrollingFrame", {
				AutomaticCanvasSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				CanvasSize = UDim2.fromScale(0.364583, 0.462963),
				Position = UDim2.fromScale(0.0394737, 0.204204),
				ScrollBarThickness = 0,
				Size = UDim2.fromScale(0.921053, 0.750751),
				ZIndex = 0,
			}, {
				user = e(LeaderboardEntry, { Username = "Username", Wins = 10000, LayoutOrder = 1 }),
				user2 = e(LeaderboardEntry, { Username = "Username", Wins = 10000, LayoutOrder = 2 }),
				user3 = e(LeaderboardEntry, { Username = "Username", Wins = 10000, LayoutOrder = 3 }),
				user4 = e(LeaderboardEntry, { Username = "Username", Wins = 10000, LayoutOrder = 4 }),
				user5 = e(LeaderboardEntry, { Username = "Username", Wins = 10000, LayoutOrder = 5 }),
				user6 = e(LeaderboardEntry, { Username = "Username", Wins = 10000, LayoutOrder = 6 }),
				user7 = e(LeaderboardEntry, { Username = "Username", Wins = 10000, LayoutOrder = 7 }),
				user8 = e(LeaderboardEntry, { Username = "Username", Wins = 10000, LayoutOrder = 8 }),

				uIListLayout = React.createElement("UIListLayout", {
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0.02, 0),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			}),
		}),

		babiesButton = e(TextButton, {
			Text = "Babies",
			Variant = "primary",
			BackgroundImage = "rbxassetid://130347638303988",
			Size = UDim2.fromScale(0.489691, 0.108108),
			CornerRadius = UDim.new(0.16, 0),
			OnClick = function()
				-- Handle babies tab click
			end,
		}),

		parentsButton = e(TextButton, {
			Text = "Parents",
			Variant = "secondary",
			BackgroundImage = "rbxassetid://125676755638326",
			Size = UDim2.fromScale(0.489691, 0.108108),
			Position = UDim2.fromScale(0.510309, 0),
			CornerRadius = UDim.new(0.16, 0),
			OnClick = function()
				-- Handle parents tab click
			end,
		}),

		mostWins = React.createElement("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			Position = UDim2.fromScale(0.252577, 0.0324324),
			Size = UDim2.fromScale(0.494845, 0.0756757),
			ZIndex = 2,
		}, {
			uICorner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0.178571, 0),
			}),

			uIGradient = React.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(47, 52, 88)),
					ColorSequenceKeypoint.new(0.89, Color3.fromRGB(47, 52, 88)),
					ColorSequenceKeypoint.new(0.91, Color3.fromRGB(43, 46, 80)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(43, 46, 80)),
				}),
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
													NumberSequenceKeypoint.new(0.89, 0),
													NumberSequenceKeypoint.new(0.91, 0),
													NumberSequenceKeypoint.new(1, 0),
				}),
			}),

			uIStroke = React.createElement("UIStroke", {
				Color = Color3.new(1, 1, 1),
				Thickness = 2,
			}),

			textLabel = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxassetid://11702779517",
					Enum.FontWeight.Heavy,
					Enum.FontStyle.Italic
				),
				Position = UDim2.fromScale(0.252903, 0),
				RichText = true,
				Size = UDim2.fromScale(0.493548, 1),
				Text = "Most Wins",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}, {
				uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 10.2,
				}),

				uIPadding = React.createElement("UIPadding", {
					PaddingBottom = UDim.new(0.26, 0),
					PaddingTop = UDim.new(0.26, 0),
				}),
			}),
		}),

		uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
			AspectRatio = 2.01297,
		}),
	})
end
