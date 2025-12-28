local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.React)
local GameConstants = require(ReplicatedStorage.Shared.Modules.Core.GameConstants)
local SoundUtils = require(ReplicatedStorage.Shared.Modules.Core.SoundUtils)
local TransitionFrameModule = require(ReplicatedStorage.UI.components.frames.TransitionFrame)

local e = React.createElement

export type TurnAnnouncementProps = {
	PlayerName: string,
	IsLocal: boolean,
}

return function(props: TurnAnnouncementProps)
	local containerRef = React.useRef(nil :: Frame?)
	local isMounted = React.useRef(true)
	local transition = React.useContext(TransitionFrameModule.Context)

	React.useEffect(function()
		return function()
			isMounted.current = false
		end
	end, {})

	React.useEffect(function()
		local container = containerRef.current
		if not container then
			return
		end

		-- Start position: Off-screen Right
		container.Position = UDim2.fromScale(1.5, 0.4)
		container.Visible = true

		-- 1. Swoop In to Center
		local swoopIn =
			TweenService:Create(container, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.fromScale(0.5, 0.4),
			})

		-- 2. Swoop Out to Left after a delay
		local swoopOut =
			TweenService:Create(container, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Position = UDim2.fromScale(-0.5, 0.4),
			})

		if not transition.isExiting then
			SoundUtils.playWoosh()
		end
		swoopIn:Play()

		task.delay(1.5, function()
			if not isMounted.current or transition.isExiting then
				return
			end
			if container.Parent then
				SoundUtils.playWoosh()
				swoopOut:Play()
			end
		end)
	end, { props.PlayerName })

	-- Choose phrase once per mount/update
	local displayText = React.useMemo(function()
		return (if props.IsLocal then "YOUR" else props.PlayerName:upper() .. "'S") .. " TURN"
	end, { props.PlayerName })

	return e("Frame", {
		ref = containerRef,
		Size = UDim2.fromScale(1, 0.2),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		BackgroundTransparency = 1,
		ZIndex = 1000,
		Visible = false,
	}, {
		TextLabel = e("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = displayText,
			TextColor3 = if props.IsLocal then Color3.fromRGB(249, 0, 149) else Color3.new(1, 1, 1),
			TextScaled = true,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
		}, {
			UIStroke = e("UIStroke", {
				Color = Color3.new(0, 0, 0),
				Thickness = 4,
			}),
			UIGradient = e("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200)),
				}),
			}),
		}),
	})
end
