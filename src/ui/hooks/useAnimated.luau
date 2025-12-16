local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local React_Otter = require(ReplicatedStorage.Packages["React-Otter"])

local Animation = {}

function Animation.createAnimatedSize(initial: number, sizeX: number?, sizeY: number?)
	sizeX = sizeX or 1
	sizeY = sizeY or 1
	local value, setGoal = React_Otter.useAnimatedBinding(initial)

	local function animate(target: number, frequency: number?, dampingRatio: number?)
		setGoal(React_Otter.spring(target, {
			frequency = frequency or 5,
			dampingRatio = dampingRatio or 1,
		}))
	end

	local animatedSize = value:map(function(scale)
		return UDim2.fromScale(sizeX * scale, sizeY * scale)
	end)

	return animatedSize, animate
end

function Animation.useScreenFade(duration: number?)
	local fadeValue, setFadeGoal = React_Otter.useAnimatedBinding(0)
	local fadeTime = duration or 1

	local function triggerFade()
		setFadeGoal(React_Otter.spring(1, { frequency = 2, dampingRatio = 1 }))
		task.delay(fadeTime / 2, function()
			setFadeGoal(React_Otter.spring(0, { frequency = 2, dampingRatio = 1 }))
		end)
	end

	local fadeElement = React.createElement("Frame", {
		BackgroundColor3 = Color3.new(0, 0, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = fadeValue:map(function(v)
			return 1 - v
		end),
		ZIndex = 9999,
	})

	return fadeElement, triggerFade
end

function Animation.createFlash(colors: {Color3}, duration: number, intensity: number, frequency: number)
	colors = colors or { Color3.fromRGB(255, 255, 255) }
	duration = duration or 0.1
	intensity = intensity or 1
	frequency = frequency or 6

	local flashValue, setFlashGoal = React_Otter.useAnimatedBinding(0)
	local flashColor, setFlashColor = React.useBinding(colors[1])

	local animatedColor = flashValue:map(function(v)
		return Color3.new(1, 1, 1):Lerp(flashColor:getValue(), v)
	end)

	local function triggerFlash(newColor: Color3?)
		if newColor then
			setFlashColor(newColor)
		end

		setFlashGoal(React_Otter.spring(intensity, {
			frequency = frequency,
			dampingRatio = 0.5,
		}))

		task.wait(duration)

		setFlashGoal(React_Otter.spring(0, {
			frequency = frequency,
			dampingRatio = 1,
		}))
	end

	return animatedColor, triggerFlash
end

-- Animated transparency (0 = invisible, 1 = fully visible)
function Animation.useAnimatedTransparency(initialVisible: boolean?)
	local value, setGoal = React_Otter.useAnimatedBinding(if initialVisible then 1 else 0)
	
	local function show()
		setGoal(React_Otter.spring(1, {
			frequency = 4,
			dampingRatio = 1,
		}))
	end
	
	local function hide()
		setGoal(React_Otter.spring(0, {
			frequency = 4,
			dampingRatio = 1,
		}))
	end
	
	-- Map to transparency (inverted: 0 visibility = 1 transparency)
	local transparency = value:map(function(v)
		return 1 - v
	end)
	
	return transparency, show, hide, value
end

-- Animated slide position (for panels sliding in from edges)
-- direction: "up", "down", "left", "right"
function Animation.useSlideIn(direction: string?, initialVisible: boolean?)
	direction = direction or "up"
	local value, setGoal = React_Otter.useAnimatedBinding(if initialVisible then 1 else 0)
	
	local function show()
		setGoal(React_Otter.spring(1, {
			frequency = 3.5,
			dampingRatio = 0.85,
		}))
	end
	
	local function hide()
		setGoal(React_Otter.spring(0, {
			frequency = 4,
			dampingRatio = 1,
		}))
	end
	
	-- Map to position based on direction
	local position = value:map(function(v)
		local offset = 1 - v -- 1 when hidden, 0 when shown
		
		if direction == "up" then
			return UDim2.fromScale(0.5, 0.5 + offset * 0.3)
		elseif direction == "down" then
			return UDim2.fromScale(0.5, 0.5 - offset * 0.3)
		elseif direction == "left" then
			return UDim2.fromScale(0.5 + offset * 0.3, 0.5)
		elseif direction == "right" then
			return UDim2.fromScale(0.5 - offset * 0.3, 0.5)
		end
		
		return UDim2.fromScale(0.5, 0.5 + offset * 0.3)
	end)
	
	return position, show, hide, value
end

-- Combined panel animation (slide + fade)
function Animation.usePanelTransition(visible: boolean, direction: string?)
	direction = direction or "up"
	
	local slideValue, setSlideGoal = React_Otter.useAnimatedBinding(if visible then 1 else 0)
	local fadeValue, setFadeGoal = React_Otter.useAnimatedBinding(if visible then 1 else 0)
	
	-- React to visibility changes
	React.useEffect(function()
		if visible then
			-- Fade in background first, then slide panel
			setFadeGoal(React_Otter.spring(1, {
				frequency = 5,
				dampingRatio = 1,
			}))
			task.delay(0.05, function()
				setSlideGoal(React_Otter.spring(1, {
					frequency = 3.5,
					dampingRatio = 0.8,
				}))
			end)
		else
			-- Slide out panel first, then fade background
			setSlideGoal(React_Otter.spring(0, {
				frequency = 5,
				dampingRatio = 1,
			}))
			task.delay(0.1, function()
				setFadeGoal(React_Otter.spring(0, {
					frequency = 5,
					dampingRatio = 1,
				}))
			end)
		end
	end, { visible })
	
	-- Background transparency (inverted)
	local bgTransparency = fadeValue:map(function(v)
		return 1 - (v * 0.6) -- Max 0.4 opacity (0.6 transparency)
	end)
	
	-- Panel position
	local panelPosition = slideValue:map(function(v)
		local offset = 1 - v
		
		if direction == "up" then
			return UDim2.fromScale(0.5, 0.5 + offset * 0.15)
		elseif direction == "down" then
			return UDim2.fromScale(0.5, 0.5 - offset * 0.15)
		elseif direction == "left" then
			return UDim2.fromScale(0.5 + offset * 0.15, 0.5)
		elseif direction == "right" then
			return UDim2.fromScale(0.5 - offset * 0.15, 0.5)
		end
		
		return UDim2.fromScale(0.5, 0.5 + offset * 0.15)
	end)
	
	-- Panel transparency (for fade effect)
	local panelTransparency = slideValue:map(function(v)
		return 1 - v
	end)
	
	-- Panel scale (subtle pop effect)
	local panelScale = slideValue:map(function(v)
		local scale = 0.95 + (v * 0.05) -- 0.95 to 1.0
		return UDim2.fromScale(0.9 * scale, 0.85 * scale) -- Larger panels
	end)
	
	-- Should render (don't render when fully hidden)
	local shouldRender = fadeValue:map(function(v)
		return v > 0.01
	end)
	
	return {
		bgTransparency = bgTransparency,
		panelPosition = panelPosition,
		panelTransparency = panelTransparency,
		panelScale = panelScale,
		shouldRender = shouldRender,
	}
end

return Animation
