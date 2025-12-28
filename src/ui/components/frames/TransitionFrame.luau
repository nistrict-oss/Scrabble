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

-- Context to let children know if they are currently being transitioned OUT
local TransitionContext = React.createContext({ isExiting = false })

-- 🧊 Frozen Wrapper: Blocks all re-renders for the fading-out content
local StaticWrapper = React.memo(function(props: { children: any })
	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, props.children)
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
	Silent: boolean?,
}

local function TransitionFrame(props: TransitionFrameProps)
	local duration = props.Duration or 0.7

	local currentGroupRef = React.useRef(nil :: Frame?)
	local oldGroupRef = React.useRef(nil :: Frame?)

	-- State tracks { current, previous, key, transitionCount }
	local state, setState = React.useState({
		current = props.children,
		previous = nil,
		key = props.TransitionKey,
		count = 0,
	})

	-- ⚡ ZERO-DELAY SYNC:
	if props.TransitionKey ~= state.key then
		setState({
			current = props.children,
			previous = state.current,
			key = props.TransitionKey,
			count = state.count + 1,
		})
	elseif props.children ~= state.current then
		setState({
			current = props.children,
			previous = state.previous,
			key = state.key,
			count = state.count,
		})
	end

	-- 3. Run Animation
	local lastPlayedCount = React.useRef(-1)

	React.useLayoutEffect(function()
		if not state.previous then
			return
		end

		local currentGroup = currentGroupRef.current
		local oldGroup = oldGroupRef.current

		-- Play transition sound once when the effect runs for a NEW transition
		if state.count > lastPlayedCount.current then
			lastPlayedCount.current = state.count
			if not props.Silent then
				SoundUtils.playWoosh()
			end
		end

		if not currentGroup or not oldGroup then
			return
		end

		local tType = props.Type or "Fade"
		local direction = props.Direction or "Right"
		local slideOffset = 1.1 -- 110% width offset for a "full" swipe
		local basePos = props.Position or UDim2.fromScale(0, 0)
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

		if tType == "Fade" then
			-- With Frame instead of CanvasGroup, we use slide animation for fade effect
			oldGroup.Visible = true
			currentGroup.Visible = true
			currentGroup.Position = UDim2.fromScale(0, 0)
			oldGroup.Position = basePos

			-- Slide old content out and new content in simultaneously
			TweenService:Create(oldGroup, tweenInfo, { Position = basePos + UDim2.fromScale(-0.1, 0) }):Play()
			local slideIn = TweenService:Create(currentGroup, tweenInfo, { Position = basePos })

			local targetCount = state.count
			local conn
			conn = slideIn.Completed:Connect(function()
				conn:Disconnect()
				oldGroup.Visible = false
				setState(function(latest)
					if latest.count == targetCount then
						return { current = latest.current, previous = nil, key = latest.key, count = latest.count }
					end
					return latest
				end)
			end)
			slideIn:Play()
		else
			-- SLIDE
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

			currentGroup.Position = currentStartPos
			oldGroup.Position = basePos
			oldGroup.Visible = true
			currentGroup.Visible = true

			TweenService:Create(oldGroup, tweenInfo, { Position = oldExitPos }):Play()
			local slideIn = TweenService:Create(currentGroup, tweenInfo, { Position = basePos })

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
	end, { state.count })

	return e("Frame", {
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = props.ZIndex or 0,
	}, {
		Previous = state.previous and e(TransitionContext.Provider, { value = { isExiting = true } }, {
			FrameWrapper = e("Frame", {
				ref = oldGroupRef,
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Visible = true,
				ZIndex = 1,
			}, {
				Static = e(StaticWrapper, {}, state.previous),
			}),
		}),

		Current = e(TransitionContext.Provider, { value = { isExiting = false } }, {
			FrameWrapper = e("Frame", {
				ref = currentGroupRef,
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Visible = true,
				ZIndex = 2,
			}, state.current),
		}),
	})
end

return {
	TransitionFrame = TransitionFrame,
	Context = TransitionContext,
}
