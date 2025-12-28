--[[
	LoadingScreen.luau
	
	Premium animated splash screen with custom music and staggered tile animations.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)
local SoundUtils = require(ReplicatedStorage.Shared.Modules.Core.SoundUtils)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)
local LetterTile = require(ReplicatedStorage.UI.components.game.LetterTile)
local InventoryServiceClient = require(ReplicatedStorage.Shared.Services.InventoryService.InventoryServiceClient)

local e = React.createElement

local LETTERS = { "S", "C", "R", "E", "B", "B", "L", "O" }
local ALL_LETTERS = {
	"A",
	"B",
	"C",
	"D",
	"E",
	"F",
	"G",
	"H",
	"I",
	"J",
	"K",
	"L",
	"M",
	"N",
	"O",
	"P",
	"Q",
	"R",
	"S",
	"T",
	"U",
	"V",
	"W",
	"X",
	"Y",
	"Z",
}
-- Premium tile component (simplified, no dependencies on game LetterTile)
local function PremiumTile(props: { letter: string, index: number, delay: number })
	local frameRef = React.useRef(nil :: Frame?)
	local hasAnimated = React.useRef(false)

	React.useEffect(function()
		local frame = frameRef.current
		if not frame or hasAnimated.current then
			return
		end
		hasAnimated.current = true

		-- Initial state: Alternating top/bottom start (WAY off screen)
		local startY = if props.index % 2 == 1 then -6 else 7 -- Odd from way above, Even from way below
		frame.Position = UDim2.fromScale(0.5, startY)
		frame.Rotation = 25 + math.random(-10, 10)
		frame.BackgroundTransparency = 1 -- Start transparent if frame

		-- Staggered entrance with pop sound
		task.delay(props.delay, function()
			if not frame or not frame.Parent then
				return
			end

			-- Swoop in with bounce (much slower animation for dramatic effect)
			TweenService:Create(frame, TweenInfo.new(2.0, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.fromScale(0.5, 0.5), -- Center in its container
				Rotation = 0,
				BackgroundTransparency = 1,
			}):Play()
		end)

		-- Gentle floating animation after arrival
		local startTime = tick() + props.delay + 0.7
		local connection = RunService.RenderStepped:Connect(function()
			if not frame or not frame.Parent then
				return
			end
			if tick() < startTime then
				return
			end

			local elapsed = tick() - startTime
			local floatY = math.sin(elapsed * 1.5 + props.index * 0.5) * 0.02
			local rotation = math.sin(elapsed * 1.2 + props.index * 0.3) * 3

			frame.Position = UDim2.fromScale(0.5, 0.5 + floatY)
			frame.Rotation = rotation
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	return e("Frame", {
		ref = frameRef, -- Need to attach ref here for animation
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5), -- Center the tile properly
		BackgroundTransparency = 1,
		LayoutOrder = props.index,
	}, {
		UIAspectRatioConstraint = e("UIAspectRatioConstraint", { AspectRatio = 1 }),

		-- Use real LetterTile inside PremiumTile structure for consistent look but with animation support
		Tile = e(LetterTile, {
			Letter = props.letter,
			Index = props.index,
			NoPop = true,
			Active = false,
		}),
	})
end

export type LoadingScreenProps = {
	OnFinished: () -> (),
}

return function(props: LoadingScreenProps)
	local canProceed, setCanProceed = React.useState(false)
	local cosmeticsLoaded, setCosmeticsLoaded = React.useState(false)
	local playButtonRef = React.useRef(nil :: Frame?)

	-- Wait for cosmetics to load so tiles render with player's colors
	React.useEffect(function()
		-- Check if already loaded (equipped colors exist beyond defaults)
		local equipped = InventoryServiceClient.EquippedColors
		if equipped and (equipped.Tile ~= nil or #InventoryServiceClient.OwnedTileColors > 0) then
			setCosmeticsLoaded(true)
			return
		end

		-- Wait for cosmetics to load from server
		local conn = InventoryServiceClient.OnTileColorsLoaded:Connect(function()
			setCosmeticsLoaded(true)
		end)

		-- Timeout fallback - don't wait forever, show with defaults after 2 seconds
		local timeoutTask = task.delay(2, function()
			setCosmeticsLoaded(true)
		end)

		return function()
			conn:Disconnect()
			task.cancel(timeoutTask)
		end
	end, {})

	-- Music Management
	React.useEffect(function()
		SoundUtils.playLobbyMusic()

		-- Show play button after animations complete (only if cosmetics loaded)
		-- If cosmetics aren't loaded yet, this will be retriggered
		if cosmeticsLoaded then
			local duration = (#LETTERS * 0.13) + 1.5
			task.delay(duration, function()
				setCanProceed(true)
			end)
		end

		-- No cleanup needed - lobby music continues
	end, { cosmeticsLoaded })

	-- Animate play button appearance
	React.useEffect(function()
		if not canProceed then
			return
		end

		local btn = playButtonRef.current
		if not btn then
			return
		end

		-- Start just below and slide up
		btn.Position = UDim2.fromScale(0.5, 0.70)

		TweenService:Create(btn, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(0.5, 0.62),
		}):Play()
	end, { canProceed })

	local particleTime, setParticleTime = React.useBinding(0)

	React.useEffect(function()
		local connection = RunService.RenderStepped:Connect(function()
			setParticleTime(tick())
		end)
		return function()
			connection:Disconnect()
		end
	end, {})

	-- Create letter tiles using real LetterTile (clickable!) - only after cosmetics loaded
	local letterElements = {}
	if cosmeticsLoaded then
		for i, letter in ipairs(LETTERS) do
			letterElements["Letter_" .. i] = e("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				LayoutOrder = i,
			}, {
				UIAspectRatioConstraint = e("UIAspectRatioConstraint", { AspectRatio = 1 }),

				-- Animated wrapper
				AnimWrapper = e(PremiumTile, {
					letter = letter,
					index = i,
					delay = (i - 1) * 0.13 + 0.3,
				}),
			})
		end
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 1000,
	}, {

		-- Floating clickable letter tiles (using real LetterTile component)
		FloatingTiles = cosmeticsLoaded
				and e(
					"Frame",
					{
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						ZIndex = 2,
					},
					(function()
						local tiles = {}
						for i = 1, 12 do
							local randomLetter = ALL_LETTERS[math.random(#ALL_LETTERS)]
							local baseX = (i - 1) / 12 + 0.04
							local speed = 0.12 + (i % 4) * 0.06
							local tileSize = 0.05 + (i % 3) * 0.01
							local startOffset = i * 0.25

							tiles["FloatTile_" .. i] = e("Frame", {
								Size = UDim2.fromScale(tileSize, tileSize),
								Position = particleTime:map(function(t)
									local y = (1.15 - ((t * speed + startOffset) % 1.3))
									local xWobble = math.sin(t * 1.5 + i) * 0.02
									return UDim2.fromScale(baseX + xWobble, y)
								end),
								Rotation = particleTime:map(function(t)
									return math.sin(t * 0.8 + i * 0.5) * 12
								end),
								BackgroundTransparency = 1,
							}, {
								UIAspectRatioConstraint = e("UIAspectRatioConstraint", { AspectRatio = 1 }),

								-- Invisible click detector on top
								ClickDetector = e("TextButton", {
									Size = UDim2.fromScale(1, 1),
									BackgroundTransparency = 1,
									Text = "",
									ZIndex = 10,
									[React.Event.Activated] = function(rbx)
										SoundUtils.playBubblePop()
										-- Just hide the tile on pop
										local container = rbx.Parent
										if not container then
											return
										end

										container.Visible = false

										-- Respawn after a delay
										task.delay(1.5, function()
											if container and container.Parent then
												container.Visible = true
											end
										end)
									end,
								}),

								-- Actual tile
								Tile = e(LetterTile, {
									Letter = randomLetter,
									Index = i,
									NoPop = true,
									Active = false,
								}),
							})
						end
						return tiles
					end)()
				)
			or nil,

		-- Title "SCRABBLE" container
		TitleContainer = e(
			"Frame",
			{
				Size = UDim2.fromScale(0.75, 0.12),
				Position = UDim2.fromScale(0.5, 0.35), -- Moved up slightly
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				ZIndex = 10,
			},
			(function()
				local children = {
					UIListLayout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						Padding = UDim.new(0.012, 0),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
				}
				-- Add letter elements
				for key, val in pairs(letterElements) do
					children[key] = val
				end
				return children
			end)()
		),

		-- Play button (animated in) - using Frame with padding for stroke
		PlayButtonWrapper = canProceed and e("Frame", {
			ref = playButtonRef,
			Size = UDim2.fromScale(0.28, 0.12),
			Position = UDim2.fromScale(0.5, 0.62),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			ZIndex = 15,
		}, {
			UIPadding = e("UIPadding", {
				PaddingLeft = UDim.new(0.05, 0),
				PaddingRight = UDim.new(0.05, 0),
				PaddingTop = UDim.new(0.08, 0),
				PaddingBottom = UDim.new(0.08, 0),
			}),
			Button = e(TextButton, {
				Text = "▶  PLAY",
				Variant = "primary",
				Size = UDim2.fromScale(1, 1),
				OnClick = props.OnFinished,
			}),
		}) or nil,

		-- Status text
		StatusText = e("TextLabel", {
			Size = UDim2.fromScale(0.5, 0.04),
			Position = UDim2.fromScale(0.5, 0.62),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Text = if canProceed then "" else "LOADING...",
			TextColor3 = Color3.new(1, 1, 1),
			TextTransparency = 0.2,
			TextScaled = true,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium, Enum.FontStyle.Italic),
			ZIndex = 10,
		}, {
			UIStroke = e("UIStroke", {
				Color = Color3.new(0, 0, 0),
				Thickness = 1.5,
				Transparency = 0.6,
			}),
		}),

		-- Bottom branding
		Branding = e("TextLabel", {
			Size = UDim2.fromScale(0.3, 0.025),
			Position = UDim2.fromScale(0.5, 0.96),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Text = "PRESTIGE WORDS",
			TextColor3 = Color3.new(1, 1, 1),
			TextTransparency = 0.5,
			TextScaled = true,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
			ZIndex = 10,
		}),
	})
end
