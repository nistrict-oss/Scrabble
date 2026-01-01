--[[
	ScoreParticle.luau
	
	An individual floating point value that animates from a source tile
	to a goal position on the scoreboard.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.React)
local SoundUtils = require(ReplicatedStorage.Shared.Modules.Core.SoundUtils)

local e = React.createElement

export type ScoreParticleProps = {
	Amount: number,
	StartPos: Vector2, -- Screen space AbsolutePosition
	EndPos: Vector2, -- Screen space AbsolutePosition
	Delay: number?, -- Optional delay to sync with board wave
	TileIndex: number?, -- Index of this tile in the word (1-based)
	TotalTiles: number?, -- Total number of tiles in the word
	OnComplete: () -> (),
}

return function(props: ScoreParticleProps)
	local camera = workspace.CurrentCamera
	local screen = camera.ViewportSize
	local startScaleX = props.StartPos.X / screen.X
	local startScaleY = props.StartPos.Y / screen.Y

	local position, setPosition = React.useBinding(UDim2.fromScale(startScaleX, startScaleY))
	local transparency, setTransparency = React.useBinding(0)
	local scale, setScale = React.useBinding(0)
	local rotation, setRotation = React.useBinding(math.random(-15, 15))

	-- Pre-create the sound instance for reliable playback
	local soundRef = React.useRef(nil :: Sound?)

	React.useEffect(function()
		-- Create and configure the sound once when the particle is created
		local GameConstants = require(ReplicatedStorage.Shared.Modules.Core.GameConstants)
		local SoundService = game:GetService("SoundService")

		local sound = Instance.new("Sound")
		sound.SoundId = GameConstants.SOUNDS.SCORE_COLLECT
		sound.Volume = (GameConstants.VOLUMES.SCORE_COLLECT or 1.0) * SoundUtils.getSFXVolume()

		-- Calculate pitch based on tile position
		-- For positive scores: ascending scale (1.0 -> 1.5)
		-- For negative scores (penalties): descending scale (0.9 -> 0.6)
		local pitch = 1.0
		if props.TileIndex and props.TotalTiles and props.TotalTiles > 0 then
			local isNegative = props.Amount < 0
			if isNegative then
				-- Descending pitch for penalties: 0.9 down to 0.6
				local progress = (props.TileIndex - 1) / math.max(props.TotalTiles - 1, 1)
				pitch = 0.9 - (progress * 0.3) -- 0.9 -> 0.6
			else
				-- Ascending pitch for positive scores: 1.0 up to 1.5
				pitch = math.min(1.0 + ((props.TileIndex - 1) * 0.025), 1.5)
			end
		end
		sound.PlaybackSpeed = pitch

		sound.Parent = SoundService
		soundRef.current = sound

		-- Auto-destroy the sound after it finishes playing
		sound.Ended:Once(function()
			sound:Destroy()
		end)

		-- Don't destroy the sound when the particle unmounts - let it finish playing
		return function()
			-- Cleanup: only destroy if the sound never played
			if soundRef.current and not soundRef.current.IsPlaying and soundRef.current.TimePosition == 0 then
				soundRef.current:Destroy()
			end
		end
	end, {})

	React.useEffect(function()
		local duration = 0.8
		local delay = props.Delay or 0
		local startTime = os.clock() + delay

		-- Custom animation loop for smooth curved path and scaling
		local connection
		connection = game:GetService("RunService").RenderStepped:Connect(function()
			local elapsed = os.clock() - startTime
			if elapsed < 0 then
				setScale(0)
				setTransparency(1)
				return
			end

			local t = math.clamp(elapsed / duration, 0, 1)

			-- Easing for t
			local alpha = TweenService:GetValue(t, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

			-- Bezier Curve calculation (midpoint arced upwards)
			local p0 = props.StartPos
			local p2 = props.EndPos
			local p1 = (p0 + p2) / 2 + Vector2.new(0, -150) -- Arc upwards

			local currentPos = (1 - alpha) ^ 2 * p0 + 2 * (1 - alpha) * alpha * p1 + alpha ^ 2 * p2
			setPosition(UDim2.fromScale(currentPos.X / screen.X, currentPos.Y / screen.Y))

			-- Pop, Scale and Transparency effects
			-- 0.0 -> 0.2: Pop in (0 to 1.2 scale)
			-- 0.2 -> 0.8: Hold (1.2 scale)
			-- 0.8 -> 1.0: Fade out (1.2 to 0 scale)
			if t < 0.2 then
				local popT = t / 0.2
				local popAlpha = TweenService:GetValue(popT, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				setScale(popAlpha * 1.2)
				setTransparency(0)
			elseif t > 0.8 then
				local fadeT = (t - 0.8) / 0.2
				setScale(1.2 * (1 - fadeT))
				setTransparency(fadeT)
			else
				setScale(1.2)
				setTransparency(0)
			end

			setRotation(math.sin(t * 10) * 10)

			if t >= 1 then
				connection:Disconnect()
				-- Play the pre-loaded sound instance
				if soundRef.current then
					soundRef.current:Play()
				end
				props.OnComplete()
			end
		end)

		return function()
			if connection then
				connection:Disconnect()
			end
		end
	end, {})

	-- Determine if this is a penalty (negative amount)
	local isNegative = props.Amount < 0
	local displayAmount = math.abs(props.Amount)
	local displayText = if isNegative then "-" .. tostring(displayAmount) else "+" .. tostring(displayAmount)
	local textColor = if isNegative then Color3.fromRGB(255, 80, 80) else Color3.fromRGB(255, 235, 100)

	return e("TextLabel", {
		Position = position,
		Size = UDim2.fromScale(0.06, 0.04),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		TextTransparency = transparency,
		Text = displayText,
		TextColor3 = textColor,
		TextScaled = true,
		FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
		Rotation = rotation,
		ZIndex = 10000,
	}, {
		UIScale = e("UIScale", {
			Scale = scale,
		}),
		UIStroke = e("UIStroke", {
			Color = Color3.new(0, 0, 0),
			Thickness = 3,
			Transparency = transparency,
		}),
	})
end
