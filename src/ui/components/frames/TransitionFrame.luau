--[[
	TransitionFrame.luau
	
	High-performance simultaneous transition wrapper.
	Optimized for ZERO render-delay using synchronous state sync.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.React)
local SoundUtils = require(ReplicatedStorage.Shared.Modules.Core.SoundUtils)

local e = React.createElement

-- 🧊 Frozen Wrapper: Blocks all re-renders for the fading-out content
local StaticWrapper = React.memo(function(props: { children: any })
	return props.children
end, function()
	return true -- Always "equal" = Never re-renders once mounted
end)

export type TransitionFrameProps = {
	TransitionKey: any,
	Duration: number?,
	Type: ("Fade" | "Slide")?,
	Direction: ("Left" | "Right")?,
	Position: UDim2?,
	Size: UDim2?,
	children: any,
	ZIndex: number?,
}

return function(props: TransitionFrameProps)
	local duration = props.Duration or 0.7

	local currentGroupRef = React.useRef(nil :: CanvasGroup?)
	local oldGroupRef = React.useRef(nil :: CanvasGroup?)

	-- State tracks { current, previous, key, transitionCount }
	local state, setState = React.useState({
		current = props.children,
		previous = nil,
		key = props.TransitionKey,
		count = 0,
	})

	local isFading, setIsFading = React.useState(false)

	-- ⚡ ZERO-DELAY SYNC:
	if props.TransitionKey ~= state.key then
		setState({
			current = props.children,
			previous = state.current,
			key = props.TransitionKey,
			count = state.count + 1,
		})
		if props.Type == "Fade" then
			setIsFading(true)
		end
		SoundUtils.playWoosh()
	elseif props.children ~= state.current then
		setState({
			current = props.children,
			previous = state.previous,
			key = state.key,
			count = state.count,
		})
	end

	-- 3. Run Animation
	React.useLayoutEffect(function()
		if not state.previous then
			return
		end

		local currentGroup = currentGroupRef.current
		local oldGroup = oldGroupRef.current
		if not currentGroup or not oldGroup then
			return
		end

		local tType = props.Type or "Fade"
		local direction = props.Direction or "Right"
		local slideOffset = 1.1 -- 110% width offset for a "full" swipe with safety margin for strokes
		local basePos = props.Position or UDim2.fromScale(0, 0)

		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

		if tType == "Fade" then
			-- SIMULTANEOUS CROSS-FADE
			oldGroup.Visible = true
			currentGroup.Visible = true
			currentGroup.GroupTransparency = 1
			oldGroup.GroupTransparency = 0

			TweenService:Create(oldGroup, tweenInfo, {
				GroupTransparency = -0.5, -- Extend to ensure full clear
			}):Play()

			local fadeIn = TweenService:Create(currentGroup, tweenInfo, {
				GroupTransparency = 0,
			})

			local targetCount = state.count
			local conn
			conn = fadeIn.Completed:Connect(function()
				conn:Disconnect()
				setState(function(latest)
					if latest.count == targetCount then
						return { current = latest.current, previous = nil, key = latest.key, count = latest.count }
					end
					return latest
				end)
				setIsFading(false)
			end)
			fadeIn:Play()
		else
			-- SIMULTANEOUS SLIDE (Fully Opaque)
			local oldExitPos = basePos
			local currentStartPos = basePos
			local offsetX = (props.Size or UDim2.fromScale(1, 1)).X.Scale * slideOffset

			if direction == "Right" then
				oldExitPos = basePos + UDim2.fromScale(-offsetX, 0)
				currentStartPos = basePos + UDim2.fromScale(offsetX, 0)
			else
				oldExitPos = basePos + UDim2.fromScale(offsetX, 0)
				currentStartPos = basePos + UDim2.fromScale(-offsetX, 0)
			end

			-- SET POSITION FIRST to prevent 1-frame "pop" at center
			currentGroup.Position = currentStartPos
			oldGroup.Position = basePos

			oldGroup.Visible = true
			currentGroup.Visible = true

			-- Keep fully opaque for a "solid" swipe feel
			currentGroup.GroupTransparency = 0
			oldGroup.GroupTransparency = 0

			TweenService:Create(oldGroup, tweenInfo, {
				Position = oldExitPos,
			}):Play()

			local slideIn = TweenService:Create(currentGroup, tweenInfo, {
				Position = basePos,
			})

			local targetCount = state.count
			local conn
			conn = slideIn.Completed:Connect(function()
				conn:Disconnect()
				setState(function(latest)
					if latest.count == targetCount then
						return { current = latest.current, previous = nil, key = latest.key, count = latest.count }
					end
					return latest
				end)
			end)
			slideIn:Play()
		end
	end, { state.count, isFading })

	return e("Frame", {
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = props.ZIndex or 0,
	}, {
		-- Layer 1: Previous content (Frozen)
		Previous = state.previous and e("CanvasGroup", {
			ref = oldGroupRef,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			GroupTransparency = 0,
			Active = false,
			Visible = true,
			ZIndex = 1,
		}, {
			Static = e(StaticWrapper, {}, state.previous),
		}),

		-- Layer 2: New content
		Current = e("CanvasGroup", {
			ref = currentGroupRef,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			GroupTransparency = if state.previous then 1 else 0,
			Visible = if state.previous then false else true,
			Active = false,
			ZIndex = 2,
		}, state.current),
	})
end
