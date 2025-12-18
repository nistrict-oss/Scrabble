--[[
	TransitionFrame.luau
	
	A wrapper component that provides smooth transitions (fade/slide) 
	whenever its TransitionKey prop changes. Uses CanvasGroup for efficiency.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

export type TransitionFrameProps = {
	TransitionKey: any, -- Change this to trigger a transition
	Duration: number?,
	Type: ("Fade" | "Slide")?,
	Direction: ("Left" | "Right")?,
	Position: UDim2?,
	Size: UDim2?,
	children: any,
	ZIndex: number?,
}

return function(props: TransitionFrameProps)
	local duration = props.Duration or 0.35
	local groupRef = React.useRef(nil :: CanvasGroup?)
	
	-- currentChildren: what's currently actually rendered in the group
	local currentChildren, setCurrentChildren = React.useState(props.children)
	-- currentKey: tracks which key the 'currentChildren' belongs to
	local currentKey, setCurrentKey = React.useState(props.TransitionKey)
	
	local lastKey = React.useRef(props.TransitionKey)
	local activeTween = React.useRef(nil :: Tween?)

	-- 1. Handle live internal updates for the SAME key (e.g. timers)
	React.useLayoutEffect(function()
		if props.TransitionKey == currentKey then
			setCurrentChildren(props.children)
		end
	end, { props.children, props.TransitionKey, currentKey })

	-- 2. Handle transition for NEW keys
	React.useLayoutEffect(function()
		if props.TransitionKey == lastKey.current then return end
		
		local group = groupRef.current
		if not group then 
			-- If ref isn't ready, just swap and pray
			setCurrentChildren(props.children)
			setCurrentKey(props.TransitionKey)
			lastKey.current = props.TransitionKey
			return 
		end

		-- Cancel any existing animation
		if activeTween.current then
			activeTween.current:Cancel()
			activeTween.current = nil
		end

		lastKey.current = props.TransitionKey
		
		local tType = props.Type or "Fade"
		local direction = props.Direction or "Right"
		
		local slideOffset = 0.2
		local basePos = props.Position or UDim2.fromScale(0, 0)
		local exitPos = basePos
		local entryStartPos = basePos

		if tType == "Slide" then
			local offsetX = (props.Size or UDim2.fromScale(1, 1)).X.Scale * slideOffset
			if direction == "Right" then
				exitPos = basePos + UDim2.fromScale(-offsetX, 0)
				entryStartPos = basePos + UDim2.fromScale(offsetX, 0)
			else
				exitPos = basePos + UDim2.fromScale(offsetX, 0)
				entryStartPos = basePos + UDim2.fromScale(-offsetX, 0)
			end
		end

		-- PHASE 1: Fade out the PREVIOUS content (which is still in state)
		local fadeOut = TweenService:Create(group, TweenInfo.new(duration/2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			GroupTransparency = 1,
			Position = exitPos,
		})
		
		activeTween.current = fadeOut
		
		local connection
		connection = fadeOut.Completed:Connect(function()
			connection:Disconnect()
			if lastKey.current ~= props.TransitionKey then return end -- Guard against interrupted transitions
			
			-- PHASE 2: SWAP the content and jump to entry position
			setCurrentChildren(props.children)
			setCurrentKey(props.TransitionKey)
			group.Position = entryStartPos
			
			-- PHASE 3: Fade in the NEW content
			local fadeIn = TweenService:Create(group, TweenInfo.new(duration/2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				GroupTransparency = 0,
				Position = basePos,
			})
			
			activeTween.current = fadeIn
			fadeIn:Play()
		end)
		
		fadeOut:Play()
	end, { props.TransitionKey })

	return e("CanvasGroup", {
		ref = groupRef,
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		GroupTransparency = 0,
		Active = false,
		ZIndex = props.ZIndex or 1,
	}, currentChildren)
end
