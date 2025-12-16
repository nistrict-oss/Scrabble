local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.React)
local ImageButton = require(ReplicatedStorage.UI.components.buttons.ImageButton)

local e = React.createElement

local function NavigatorButton(buttonProps)
	local isSelected = buttonProps.ActiveTab == buttonProps.TabName
	
	return e(ImageButton, {
		Image = buttonProps.UnselectedImage,
		SelectedImage = buttonProps.SelectedImage,
		Selected = isSelected,
		LayoutOrder = buttonProps.LayoutOrder or 0,
		Size = UDim2.fromScale(0.06, 0.8),
		OnClick = function()
			if buttonProps.OnTabChange then
				buttonProps.OnTabChange(buttonProps.TabName)
			end
		end,
	})
end

return function(props)
	local activeTab = props.ActiveTab or "Customization"
	local onTabChange = props.OnTabChange
	
	local player = Players.LocalPlayer
	local displayName = player and ("@" .. player.Name) or "@Player"
	local userId = player and player.UserId or 0
	local thumbnailUrl = userId > 0 
		and ("rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=150&h=150")
		or "rbxassetid://115758187032362"

	return e("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 0.138889),
	}, {
		uIGradient = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 110, 201)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(63, 140, 234)),
			}),
			Rotation = 90,
		}),

		background = e("ImageLabel", {
			BackgroundTransparency = 1,
			Image = "rbxassetid://94493965475122",
			Size = UDim2.fromScale(1, 1.11333),
			ZIndex = 0,
		}),

		userName = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.ExtraBold, Enum.FontStyle.Italic),
			Position = UDim2.fromScale(0.220833, 0.386667),
			RichText = true,
			Size = UDim2.fromScale(0.0458333, 0.16),
			Text = displayName,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			ZIndex = 2,
		}, {
			uIAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 3.66667,
			}),

			uIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.166667, 0),
			}),
		}),

		navigator = e("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			Position = UDim2.fromScale(0.282292, 0.22),
			Size = UDim2.fromScale(0.520833, 0.5),
			ZIndex = 3,
		}, {
			uICorner = e("UICorner", {
				CornerRadius = UDim.new(0.133333, 0),
			}),

			uIGradient = e("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 99, 174)),
					ColorSequenceKeypoint.new(0.89, Color3.fromRGB(90, 99, 174)),
					ColorSequenceKeypoint.new(0.91, Color3.fromRGB(81, 88, 156)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(81, 88, 156)),
				}),
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.89, 0),
					NumberSequenceKeypoint.new(0.91, 0),
					NumberSequenceKeypoint.new(1, 0),
				}),
			}),

			UIStroke = e("UIStroke", {
				Color = Color3.new(1, 1, 1),
				Thickness = 2,
			}),

			uIAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 13.3333,
			}),

			uIListLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0.02, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			shop = e(NavigatorButton, {
				TabName = "Shop",
				ActiveTab = activeTab,
				OnTabChange = onTabChange,
				UnselectedImage = "rbxassetid://79624293413130",
				SelectedImage = "rbxassetid://105172745487867",
			}),

			settings = e(NavigatorButton, {
				TabName = "Settings",
				ActiveTab = activeTab,
				OnTabChange = onTabChange,
				LayoutOrder = 2,
				UnselectedImage = "rbxassetid://116515403472692",
				SelectedImage = "rbxassetid://98033026835588",
			}),

			servers = e(NavigatorButton, {
				TabName = "Servers",
				ActiveTab = activeTab,
				OnTabChange = onTabChange,
				LayoutOrder = -1,
				UnselectedImage = "rbxassetid://134714862487905",
				SelectedImage = "rbxassetid://125569767011561",
			}),

			leaderboards = e(NavigatorButton, {
				TabName = "Leaderboards",
				ActiveTab = activeTab,
				OnTabChange = onTabChange,
				LayoutOrder = 1,
				UnselectedImage = "rbxassetid://88477302958496",
				SelectedImage = "rbxassetid://96052339210237",
			}),

			customization = e(NavigatorButton, {
				TabName = "Customization",
				ActiveTab = activeTab,
				OnTabChange = onTabChange,
				UnselectedImage = "rbxassetid://77508984950500",
				SelectedImage = "rbxassetid://127186202712390",
			}),
		}),

		currency = e("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			Position = UDim2.fromScale(0.81875, 0.22),
			Size = UDim2.fromScale(0.164062, 0.5),
			ZIndex = 4,
		}, {
			uICorner = e("UICorner", {
				CornerRadius = UDim.new(0.133333, 0),
			}),

			uIGradient = e("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 99, 174)),
					ColorSequenceKeypoint.new(0.89, Color3.fromRGB(90, 99, 174)),
					ColorSequenceKeypoint.new(0.91, Color3.fromRGB(81, 88, 156)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(81, 88, 156)),
				}),
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.89, 0),
					NumberSequenceKeypoint.new(0.91, 0),
					NumberSequenceKeypoint.new(1, 0),
				}),
			}),

			uIStroke = e("UIStroke", {
				Color = Color3.new(1, 1, 1),
				Thickness = 2,
			}),

			currencyIndicator = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.ExtraBold, Enum.FontStyle.Italic),
				Position = UDim2.fromScale(0.457143, 0.173333),
				RichText = true,
				Size = UDim2.fromScale(0.4, 0.653333),
				Text = "10000",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextYAlignment = Enum.TextYAlignment.Top,
				ZIndex = 0,
			}, {
				uIAspectRatioConstraint = e("UIAspectRatioConstraint", {
					AspectRatio = 2.57143,
				}),

				uIPadding = e("UIPadding", {
					PaddingBottom = UDim.new(0.183673, 0),
				}),
			}),

			icon = e("ImageLabel", {
				BackgroundTransparency = 1,
				Image = "rbxassetid://76014729251663",
				Position = UDim2.fromScale(0.142857, 0.16),
				Size = UDim2.fromScale(0.15873, 0.666667),
			}),

			uIAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 4.2,
			}),
		}),

		pFP = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.155729, 0.133333),
			Size = UDim2.fromScale(0.0520833, 0.666667),
		}, {
			userProfileBackground = e("Frame", {
				BackgroundColor3 = Color3.fromRGB(2, 181, 221),
				Size = UDim2.fromScale(1, 1),
				ZIndex = 0,
			}, {
				uICorner = e("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),

				uIStroke = e("UIStroke", {
					Color = Color3.new(1, 1, 1),
					Thickness = 2,
				}),
			}),

			userPFP = e("ImageLabel", {
				BackgroundTransparency = 1,
				Image = thumbnailUrl,
				Size = UDim2.fromScale(1, 1),
			}, {
				uICorner = e("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
			}),

			uIAspectRatioConstraint = e("UIAspectRatioConstraint"),
		}),
	})
end
