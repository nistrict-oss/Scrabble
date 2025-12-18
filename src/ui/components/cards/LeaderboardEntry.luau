local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

export type LeaderboardEntryProps = {
	Username: string,
	UserId: number?,
	StatName: string,
	Stat: number,
	LayoutOrder: number?,
}

return function(props: LeaderboardEntryProps)
	local thumbnailUrl = if props.UserId and props.UserId > 0
		then ("rbxthumb://type=AvatarHeadShot&id=" .. props.UserId .. "&w=150&h=150")
		else ""

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.08),
		LayoutOrder = props.LayoutOrder,
		ZIndex = 0,
	}, {
		userPFP = e("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			Size = UDim2.fromScale(0.0571429, 1),
			ZIndex = 0,
		}, {
			uICorner = e("UICorner", {
				CornerRadius = UDim.new(2.5, 0),
			}),

			userPFP = e("ImageLabel", {
				BackgroundTransparency = 1,
				Image = thumbnailUrl,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 0,
			}),
		}),

		userName = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.new(
				"rbxassetid://11702779517",
				Enum.FontWeight.ExtraBold,
				Enum.FontStyle.Italic
			),
			Position = UDim2.fromScale(0.0714286, 0.2),
			RichText = true,
			Size = UDim2.fromScale(0.187143, 0.6),
			Text = "@" .. props.Username,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		}, {
			uIAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 5.45833,
			}),

			uIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.166667, 0),
			}),
		}),

		wins = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.new(
				"rbxassetid://11702779517",
				Enum.FontWeight.ExtraBold,
				Enum.FontStyle.Italic
			),
			Position = UDim2.fromScale(0.921429, 0.2),
			RichText = true,
			Size = UDim2.fromScale(0.0785714, 0.6),
			Text = props.StatName,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Top,
			ZIndex = 2,
		}, {
			uIAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 2.29167,
			}),

			uIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.166667, 0),
			}),
		}),

		winsIndicator = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.new(
				"rbxassetid://11702779517",
				Enum.FontWeight.ExtraBold,
				Enum.FontStyle.Italic
			),
			Position = UDim2.fromScale(0.824286, 0.2),
			RichText = true,
			Size = UDim2.fromScale(0.09, 0.6),
			Text = tostring(props.Stat),
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Top,
			ZIndex = 3,
		}, {
			uIAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 2.625,
			}),

			uIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.166667, 0),
			}),
		}),
	})
end
