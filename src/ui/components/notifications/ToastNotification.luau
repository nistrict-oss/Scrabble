--[[
	ToastNotification.luau
	
	Individual toast notification component with slide-in animation.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.React)
local SoundUtils = require(ReplicatedStorage.Shared.Modules.Core.SoundUtils)

local e = React.createElement

-- Color schemes for different notification types
local TYPE_COLORS = {
	success = {
		bg = Color3.fromRGB(46, 160, 67),
		icon = "✓",
	},
	error = {
		bg = Color3.fromRGB(218, 54, 51),
		icon = "X",
	},
	warning = {
		bg = Color3.fromRGB(227, 179, 65),
		icon = "⚠",
	},
	info = {
		bg = Color3.fromRGB(58, 134, 255),
		icon = "ℹ",
	},
}

export type ToastNotificationProps = {
	Message: string,
	Type: "success" | "error" | "warning" | "info",
	OnDismiss: () -> (),
	Index: number,
}

return function(props: ToastNotificationProps)
	local message = props.Message
	local notifType = props.Type or "info"
	local onDismiss = props.OnDismiss
	local index = props.Index or 1

	local colors = TYPE_COLORS[notifType] or TYPE_COLORS.info
	local frameRef = React.useRef(nil :: Frame?)

	-- Slide-in animation on mount + play sound based on type
	React.useEffect(function()
		-- Play appropriate sound based on notification type
		if notifType == "success" then
			SoundUtils.playPurchaseSuccess()
		elseif notifType == "error" then
			SoundUtils.playWrong()
		end

		if frameRef.current then
			local frame = frameRef.current
			-- Start off-screen to the right
			frame.Position = UDim2.new(1.5, 0, 0, 10 + (index - 1) * 60)

			-- Animate in
			local tweenIn = TweenService:Create(
				frame,
				TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Position = UDim2.new(1, -10, 0, 10 + (index - 1) * 60) }
			)
			tweenIn:Play()
		end
	end, {})

	local function handleDismiss()
		if frameRef.current then
			local frame = frameRef.current
			-- Animate out
			local tweenOut = TweenService:Create(
				frame,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = UDim2.new(1.5, 0, 0, 10 + (index - 1) * 60) }
			)
			tweenOut:Play()
			tweenOut.Completed:Connect(function()
				if onDismiss then
					onDismiss()
				end
			end)
		else
			if onDismiss then
				onDismiss()
			end
		end
	end

	return e("Frame", {
		ref = frameRef,
		Size = UDim2.fromOffset(280, 50),
		Position = UDim2.new(1, -10, 0, 10 + (index - 1) * 60),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = colors.bg,
		BorderSizePixel = 0,
		ZIndex = 100,
	}, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),

		UIStroke = e("UIStroke", {
			Color = Color3.new(1, 1, 1),
			Transparency = 0.7,
			Thickness = 1,
		}),

		Icon = e("TextLabel", {
			Size = UDim2.fromOffset(40, 40),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = colors.icon,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 24,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
		}),

		Message = e("TextLabel", {
			Size = UDim2.new(1, -80, 1, 0),
			Position = UDim2.fromOffset(40, 0),
			BackgroundTransparency = 1,
			Text = message,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium),
		}),

		CloseButton = e("TextButton", {
			Size = UDim2.fromOffset(30, 30),
			Position = UDim2.new(1, -5, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Text = "×",
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 24,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
			[React.Event.Activated] = handleDismiss,
		}),
	})
end
