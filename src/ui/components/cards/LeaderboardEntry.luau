local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

export type LeaderboardEntryProps = {
	Rank: number,
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
		Size = UDim2.fromScale(1, 0.1),
		LayoutOrder = props.LayoutOrder,
		ZIndex = 0,
	}, {
		rankLabel = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			Position = UDim2.fromScale(0.01, 0.2), -- Far left
			Size = UDim2.fromScale(0.04, 0.6),
			Text = "#" .. tostring(props.Rank),
			TextColor3 = Color3.fromHex("#E0E0E0"),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		}),

		userPFP = e("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			Position = UDim2.fromScale(0.06, 0), -- Shifted right
			Size = UDim2.fromScale(0.05, 1),
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

			UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 1,
			}),
		}),

		UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
			AspectRatio = 20,
		}),

		userName = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.ExtraBold, Enum.FontStyle.Italic),
			Position = UDim2.fromScale(0.12, 0.2), -- Shifted right
			RichText = true,
			Size = UDim2.fromScale(0.187143, 0.6),
			Text = "@" .. props.Username,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		}),

		wins = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.ExtraBold, Enum.FontStyle.Italic),
			Position = UDim2.fromScale(0.85, 0.2),
			RichText = true,
			Size = UDim2.fromScale(0.0785714, 0.6),
			Text = props.StatName,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 2,
		}),

		winsIndicator = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.ExtraBold, Enum.FontStyle.Italic),
			Position = UDim2.fromScale(0.75, 0.2),
			RichText = true,
			Size = UDim2.fromScale(0.09, 0.6),
			Text = tostring(props.Stat),
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 3,
		}),
	})
end
