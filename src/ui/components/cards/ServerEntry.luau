local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local GameConstants = require(ReplicatedStorage.Shared.Modules.Core.GameConstants)
local ImageButton = require(ReplicatedStorage.UI.components.buttons.ImageButton)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)

local e = React.createElement

export type ServerEntryProps = {
	LobbyName: string?,
	HostName: string,
	HostUserId: number?,
	PlayerCount: number,
	MaxPlayers: number,
	IsPrivate: boolean?,
	LayoutOrder: number?,
	Phase: string?,
	OnJoin: (() -> ())?,
	OnSpectate: (() -> ())?,
}

return function(props: ServerEntryProps)
	local thumbnailUrl = if props.HostUserId and props.HostUserId > 0
		then ("rbxthumb://type=AvatarHeadShot&id=" .. props.HostUserId .. "&w=150&h=150")
		else "rbxassetid://131993970322393"

	return e("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.new(1, 0, 0, 80),
		LayoutOrder = props.LayoutOrder,
		ZIndex = 0,
	}, {
		uICorner = e("UICorner", {
			CornerRadius = UDim.new(0.09875, 0),
		}),

		UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
			AspectRatio = 10,
		}),

		uIGradient = e("UIGradient", {
			Color = ColorSequence.new(GameConstants.Gradients.frame),
			Rotation = 90,
		}),

		uIStroke = e("UIStroke", {
			Color = Color3.new(1, 1, 1),
			Thickness = 2,
		}),

		background = e("ImageLabel", {
			BackgroundTransparency = 1,
			Image = "rbxassetid://94988491158203",
			Size = UDim2.fromScale(1, 0.9875),
			ZIndex = 0,
		}),

		host = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.02, 0.01),
			Size = UDim2.fromScale(0.06, 0.98),
		}, {
			userPFP = e("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0, 0.192308),
				Size = UDim2.fromScale(1, 0.615385),
				ZIndex = 0,
			}, {
				userProfileBackground = e("Frame", {
					BackgroundColor3 = Color3.fromRGB(2, 181, 221),
					Size = UDim2.fromScale(1, 1),
					ZIndex = 0,
				}, {
					uICorner = e("UICorner", {
						CornerRadius = UDim.new(1.25, 0),
					}),
				}),

				userPFP = e("ImageLabel", {
					BackgroundTransparency = 1,
					Image = thumbnailUrl,
					Size = UDim2.fromScale(1, 1),
					ScaleType = Enum.ScaleType.Fit,
					ImageColor3 = Color3.fromRGB(255,255,255), 
				}, {
					uICorner = e("UICorner", {
						CornerRadius = UDim.new(1, 0),
					}),
					uIStroke = e("UIStroke", {
						Color = Color3.new(1, 1, 1),
						Thickness = 2,
					}),
				}),
			}),

			hostName = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.ExtraBold, Enum.FontStyle.Italic),
				Position = UDim2.fromScale(1.1, 0.5),
				RichText = true,
				Size = UDim2.fromScale(4, 0.3),
				Text = "Host: " .. props.HostName,
				TextColor3 = Color3.fromRGB(200, 200, 200),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, {
				uIAspectRatioConstraint = e("UIAspectRatioConstraint", {
					AspectRatio = 3.55,
				}),

				uIPadding = e("UIPadding", {
					PaddingBottom = UDim.new(0.1, 0),
					PaddingTop = UDim.new(0.1, 0),
				}),
			}),

			lobbyName = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Normal),
				Position = UDim2.fromScale(1.1, 0.1),
				RichText = true,
				Size = UDim2.fromScale(5, 0.4),
				Text = props.LobbyName or "Game Lobby",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 2,
			}, {
				uIAspectRatioConstraint = e("UIAspectRatioConstraint", {
					AspectRatio = 8,
				}),

				uIPadding = e("UIPadding", {
					PaddingBottom = UDim.new(0.05, 0),
					PaddingTop = UDim.new(0.05, 0),
				}),
			}),

			lock = props.IsPrivate and e("ImageLabel", {
				Image = "rbxassetid://111265703348733",
				Size = UDim2.fromScale(0.813253, 0.481928),
				Position = UDim2.fromScale(2.8, 0.42),
				ScaleType = Enum.ScaleType.Fit,
				BackgroundTransparency = 1,
			}) or nil,
		}),

		joinButton = e(TextButton, {
			Text = if props.Phase ~= "lobby"
				then "Started"
				elseif props.PlayerCount >= props.MaxPlayers then "Full"
				else "Join",
			Variant = "primary",
			BackgroundImage = "rbxassetid://71123294591402",
			Size = UDim2.fromScale(0.10737, 0.822917),
			Position = UDim2.fromScale(0.88, 0.0855833),
			CornerRadius = UDim.new(0.08, 0),
			ZIndex = 2,
			IsDisabled = props.Phase ~= "lobby" or props.PlayerCount >= props.MaxPlayers,
			OnClick = props.OnJoin or function() end,
		}),

		spectate = if props.Phase ~= "lobby"
			then e(TextButton, {
				BackgroundColor3 = Color3.new(1, 1, 1),
				Position = UDim2.fromScale(0.76387, 0.0855833),
				BackgroundImage = "rbxassetid://71123294591402",
				Size = UDim2.fromScale(0.10737, 0.822917),
				CornerRadius = UDim.new(0.08, 0),
				ZIndex = 2,
				Text = "Spectate",
				Variant = "secondary",
				OnClick = props.OnSpectate or function() end,
			}, {

				uIStroke = e("UIStroke", {
					Color = Color3.new(1, 1, 1),
					Thickness = 2,
				}),

				eyeUnselected = e("ImageLabel", {
					BackgroundTransparency = 1,
					Image = "rbxassetid://84735663475952",
					Position = UDim2.fromScale(0.264, 0.264),
					Size = UDim2.fromScale(0.48, 0.48),
				}),
			})
			else nil,

		playerCount = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
			Position = if props.Phase ~= "lobby"
				then UDim2.fromScale(0.66, 0.506917)
				else UDim2.fromScale(0.78, 0.506917),
			RichText = true,
			Size = UDim2.fromScale(0.0412903, 0.289667),
			Text = props.PlayerCount .. "/" .. props.MaxPlayers,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 4,
		}, {
			uIAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 1.45455,
			}),

			uIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.0909091, 0),
				PaddingTop = UDim.new(0.0909091, 0),
			}),
		}),

		playersLabel = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
			Position = if props.Phase ~= "lobby"
				then UDim2.fromScale(0.66, 0.17775)
				else UDim2.fromScale(0.78, 0.17775),
			RichText = true,
			Size = UDim2.fromScale(0.0948387, 0.289667),
			Text = "Players",
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
		}, {
			uIAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 3.34091,
			}),

			uIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.0909091, 0),
				PaddingTop = UDim.new(0.0909091, 0),
			}),
		}),
	})
end
