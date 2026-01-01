--[[
	EndGameAnnouncement.luau
	
	Shows a swooping announcement for end game scenarios:
	- Player placed all tiles
	- Time ran out
	- All players passed
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.React)
local SoundUtils = require(ReplicatedStorage.Shared.Modules.Core.SoundUtils)
local TransitionFrameModule = require(ReplicatedStorage.UI.components.frames.TransitionFrame)

local e = React.createElement

export type EndGameAnnouncementProps = {
	Message: string, -- Full message to display (e.g., "PLAYER HAS PLACED ALL THEIR TILES!")
}

return function(props: EndGameAnnouncementProps)
	local containerRef = React.useRef(nil :: Frame?)
	local subtitleRef = React.useRef(nil :: TextLabel?)
	local isMounted = React.useRef(true)
	local transition = React.useContext(TransitionFrameModule.Context)

	React.useEffect(function()
		return function()
			isMounted.current = false
		end
	end, {})

	React.useEffect(function()
		local container = containerRef.current
		local subtitle = subtitleRef.current
		if not container then
			return
		end

		-- Start position: Off-screen Right
		container.Position = UDim2.fromScale(1.5, 0.4)
		container.Visible = true

		-- Hide subtitle initially
		if subtitle then
			subtitle.TextTransparency = 1
		end

		-- 1. Swoop In to Center
		print("EndGameAnnouncement: Swooping in!")
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

		-- Fade in subtitle after swoop in completes
		task.delay(0.8, function()
			if not isMounted.current or transition.isExiting then
				return
			end
			if subtitle and subtitle.Parent then
				local fadeIn = TweenService:Create(
					subtitle,
					TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ TextTransparency = 0 }
				)
				fadeIn:Play()
			end
		end)

		task.delay(2.5, function()
			if not isMounted.current or transition.isExiting then
				return
			end
			if container.Parent then
				SoundUtils.playWoosh()
				swoopOut:Play()
			end
		end)
	end, { props.Message })

	return e("Frame", {
		ref = containerRef,
		Size = UDim2.fromScale(1, 0.25),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		BackgroundTransparency = 1,
		ZIndex = 1000,
		Visible = false,
	}, {
		-- Main announcement text
		MainText = e("TextLabel", {
			Size = UDim2.fromScale(1, 0.7),
			Position = UDim2.fromScale(0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Text = props.Message,
			TextColor3 = Color3.fromRGB(255, 215, 0), -- Gold
			TextScaled = true,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
		}, {
			UIStroke = e("UIStroke", {
				Color = Color3.new(0, 0, 0),
				Thickness = 4,
			}),
		}),

		-- Subtitle about point subtraction
		Subtitle = e("TextLabel", {
			ref = subtitleRef,
			Size = UDim2.fromScale(0.8, 0.25),
			Position = UDim2.fromScale(0.5, 0.75),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Text = "Final scores being calculated...",
			TextColor3 = Color3.fromRGB(220, 180, 120), -- Lighter gold
			TextTransparency = 1, -- Start hidden
			TextScaled = true,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium, Enum.FontStyle.Italic),
		}, {
			UIStroke = e("UIStroke", {
				Color = Color3.new(0, 0, 0),
				Thickness = 2,
			}),
		}),
	})
end
