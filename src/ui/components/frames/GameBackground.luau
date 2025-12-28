--[[
	GameBackground.luau
	
	Standardized "perfect" background used throughout the game.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

export type GameBackgroundProps = {
	ZIndex: number?,
}

return function(props: GameBackgroundProps)
	-- Shared animation logic
	local bgHue, setBgHue = React.useBinding(0.58)
	local bgRotation, setBgRotation = React.useBinding(0)

	React.useEffect(function()
		local connection = RunService.RenderStepped:Connect(function()
			local now = tick()
			-- Oscillate within cool blue range (0.55 to 0.62)
			local hue = 0.58 + math.sin(now * 0.2) * 0.04
			setBgHue(hue)
			setBgRotation((now * 3) % 360)
		end)
		return function()
			connection:Disconnect()
		end
	end, {})

	return e(React.Fragment, nil, {
		Background = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = props.ZIndex or 0,
		}, {
			UIGradient = e("UIGradient", {
				Rotation = bgRotation,
				Color = bgHue:map(function(h)
					local baseH = h
					local baseS = 0.850
					local baseV = 1.000
					return ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHSV(baseH, baseS, baseV)),
						ColorSequenceKeypoint.new(1, Color3.fromHSV((baseH + 0.05) % 1, baseS - 0.1, baseV)),
					})
				end),
			}),
		}),

		Decoration = e("ImageLabel", {
			BackgroundTransparency = 1,
			Image = "rbxassetid://78034675625122",
			Position = UDim2.fromScale(-0.15, -0.4),
			Size = UDim2.fromScale(1.5, 2.2),
			ZIndex = (props.ZIndex or 0) + 1,
			ImageColor3 = Color3.new(1, 1, 1),
			ImageTransparency = 0.8,
		}),
	})
end
