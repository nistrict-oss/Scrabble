--[[
	InGameVolumeSlider.luau
	
	Compact volume slider for in-game UI, styled like the settings screen slider.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage.Packages.React)
local GameConstants = require(ReplicatedStorage.Shared.Modules.Core.GameConstants)
local SettingsServiceClient = require(ReplicatedStorage.Shared.Services.SettingsService.SettingsServiceClient)

local e = React.createElement

return function(_props)
	-- Subscribe to settings changes
	local volume, setVolume = React.useState(SettingsServiceClient.Settings.GameMusicVolume or 0.3)

	React.useEffect(function()
		local conn = SettingsServiceClient.OnSettingUpdated:Connect(function(name, val)
			if name == "GameMusicVolume" then
				setVolume(val)
			end
		end)
		return function()
			conn:Disconnect()
		end
	end, {})

	local isDragging, setIsDragging = React.useState(false)
	local sliderRef = React.useRef(nil :: Frame?)

	-- Local visual position for immediate feedback during dragging
	local visualProgress, setVisualProgress = React.useBinding(volume)

	-- Sync visual progress with actual progress when not dragging
	React.useEffect(function()
		if not isDragging then
			setVisualProgress(volume)
		end
	end, { volume, isDragging })

	local function updateSlider(input: InputObject)
		local sliderFrame = sliderRef.current
		if not sliderFrame then
			return
		end

		local absolutePosition = sliderFrame.AbsolutePosition
		local absoluteSize = sliderFrame.AbsoluteSize

		if absoluteSize.X <= 0 then
			return
		end

		local relativeX = (input.Position.X - absolutePosition.X) / absoluteSize.X
		local newValue = math.clamp(relativeX, 0, 1)

		-- Update visual position immediately for smooth feedback
		setVisualProgress(newValue)

		SettingsServiceClient:updateSetting("GameMusicVolume", newValue)
	end

	React.useEffect(function()
		if not isDragging then
			return
		end

		local connection = UserInputService.InputChanged:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			then
				updateSlider(input)
			end
		end)

		local endConnection = UserInputService.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				setIsDragging(false)
			end
		end)

		return function()
			connection:Disconnect()
			endConnection:Disconnect()
		end
	end, { isDragging })

	return e("Frame", {
		Size = UDim2.fromScale(1, 1), -- Fill container
		BackgroundTransparency = 1,
		ZIndex = 10,
	}, {
		-- Settings-style background image
		Background = e("ImageLabel", {
			BackgroundTransparency = 1,
			Image = "rbxassetid://137904107688579",
			Size = UDim2.fromScale(1, 1),
			ZIndex = 0,
			ImageColor3 = Color3.new(1, 1, 1),
		}),

		-- Volume icon/label
		SettingName = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
			Position = UDim2.fromScale(0.2, 0.28),
			Size = UDim2.fromScale(0.18, 0.44),
			Text = "🔊",
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),

		-- Value label
		ValueLabel = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
			Position = UDim2.fromScale(0.27, 0.28),
			Size = UDim2.fromScale(0.08, 0.44),
			Text = tostring(math.round(volume * 100)),
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Right,
		}),

		-- Slider container
		SliderContainer = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.55, 0),
			Size = UDim2.fromScale(0.33, 1),
			ref = sliderRef,
			[React.Event.InputBegan] = function(_, input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					setIsDragging(true)
					updateSlider(input)
				end
			end,
		}, {
			-- Track
			Track = e("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				BackgroundColor3 = Color3.fromRGB(40, 45, 80),
				Size = UDim2.fromScale(1, 0.3),
				BorderSizePixel = 0,
				ClipsDescendants = true,
			}, {
				UICorner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
				UIStroke = e("UIStroke", {
					Color = Color3.new(1, 1, 1),
					Thickness = 1,
					Transparency = 0.5,
				}),

				-- Fill
				Fill = e("Frame", {
					BackgroundColor3 = Color3.new(1, 1, 1),
					Size = visualProgress:map(function(p)
						return UDim2.fromScale(p, 1)
					end),
					BorderSizePixel = 0,
				}, {
					UICorner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
					UIGradient = e("UIGradient", {
						Color = ColorSequence.new(GameConstants.Gradients.buttonActive),
						Rotation = 90,
					}),
				}),
			}),

			-- Handle
			Handle = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.new(1, 1, 1),
				Position = visualProgress:map(function(p)
					return UDim2.fromScale(p, 0.5)
				end),
				Size = UDim2.fromScale(0.08, 0.8),
				ZIndex = 2,
			}, {
				UIAspectRatioConstraint = e("UIAspectRatioConstraint", { AspectRatio = 1 }),
				UICorner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
				UIStroke = e("UIStroke", {
					Color = Color3.new(1, 1, 1),
					Thickness = 2,
				}),
				UIGradient = e("UIGradient", {
					Color = ColorSequence.new(GameConstants.Gradients.buttonActive),
					Rotation = 90,
				}),
			}),
		}),
	})
end
