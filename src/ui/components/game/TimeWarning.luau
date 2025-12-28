--[[
	TimeWarning.luau
	
	In-game time warning overlay that shows when the player is running low on time.
	Shows at 30s (yellow) and 10s (red, pulsing).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

export type TimeWarningProps = {
	TimeRemaining: number?, -- Seconds remaining
	IsVisible: boolean,
}

return function(props: TimeWarningProps)
	local timeRemaining = props.TimeRemaining or 0
	local isVisible = props.IsVisible

	-- Animation state for pulsing
	local pulseAlpha, setPulseAlpha = React.useBinding(0)

	-- Pulsing animation for critical time
	React.useEffect(function()
		if not isVisible or timeRemaining > 10 then
			return
		end

		-- Critical time: pulsing animation
		local connection = RunService.Heartbeat:Connect(function()
			local t = os.clock()
			-- Faster pulse as time decreases
			local speed = if timeRemaining <= 5 then 8 else 4
			local alpha = (math.sin(t * speed) + 1) / 2
			setPulseAlpha(alpha)
		end)

		return function()
			connection:Disconnect()
		end
	end, { isVisible, timeRemaining <= 10 } :: { any })

	if not isVisible then
		return nil
	end

	-- Determine warning level
	local isCritical = timeRemaining <= 10
	local isWarning = timeRemaining <= 30 and not isCritical

	if not isCritical and not isWarning then
		return nil
	end

	-- Colors based on severity
	local bgColor = if isCritical then Color3.fromRGB(220, 50, 50) else Color3.fromRGB(227, 179, 65)
	local textColor = Color3.new(1, 1, 1)
	local message = if isCritical then "⚠ TIME CRITICAL!" else "⏱ " .. math.floor(timeRemaining) .. "s remaining"

	-- Apply pulsing effect for critical time
	local transparency = if isCritical
		then pulseAlpha:map(function(a)
			return 0.3 + (a * 0.4)
		end)
		else 0.3

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.fromScale(0.5, 0.08),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = bgColor,
		BackgroundTransparency = transparency,
		ZIndex = 50,
	}, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),

		UIPadding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 20),
			PaddingRight = UDim.new(0, 20),
		}),

		Message = e("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = message,
			TextColor3 = textColor,
			TextSize = 20,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
			TextXAlignment = Enum.TextXAlignment.Center,
		}),
	})
end
