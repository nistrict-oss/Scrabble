--[[
	SettingSlider.luau
	
	A slider component for numeric settings (e.g., volume).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage.Packages.React)
local GameConstants = require(ReplicatedStorage.Shared.Modules.Core.GameConstants)

local e = React.createElement

export type SettingSliderProps = {
	Name: string,
	Value: number,
	Min: number?,
	Max: number?,
	LayoutOrder: number?,
	OnChange: ((newValue: number) -> ())?,
	IsDisabled: boolean?,
}

return function(props: SettingSliderProps)
	local isDragging, setIsDragging = React.useState(false)
	local sliderRef = React.useRef(nil :: Frame?)
	local onChangeRef = React.useRef(props.OnChange)

	local min = props.Min or 0
	local max = props.Max or 1
	local value = props.Value
	local progress = math.clamp((value - min) / (max - min), 0, 1)

	-- Local visual position for immediate feedback during dragging
	-- Initialize with actual progress to avoid visual snap on mount
	local visualProgress, setVisualProgress = React.useBinding(progress)

	-- Keep onChangeRef up to date without re-triggering effects
	React.useEffect(function()
		onChangeRef.current = props.OnChange
	end, { props.OnChange })

	-- Sync visual progress with actual progress when not dragging
	React.useEffect(function()
		if not isDragging then
			setVisualProgress(progress)
		end
	end, { progress, isDragging })

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
		local newProgress = math.clamp(relativeX, 0, 1)
		local newValue = min + (max - min) * newProgress

		-- Update visual position immediately for smooth feedback
		setVisualProgress(newProgress)

		if onChangeRef.current then
			onChangeRef.current(newValue)
		end
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
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.165289),
		LayoutOrder = props.LayoutOrder,
		ZIndex = 0,
	}, {
		background = e("ImageLabel", {
			BackgroundTransparency = 1,
			Image = "rbxassetid://137904107688579",
			Size = UDim2.fromScale(1, 1),
			ZIndex = 0,
			ImageColor3 = if props.IsDisabled then Color3.fromRGB(150, 150, 150) else Color3.new(1, 1, 1),
		}),

		settingName = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
			Position = UDim2.fromScale(0.0180645, 0.28),
			RichText = true,
			Size = UDim2.fromScale(0.173548, 0.44),
			Text = props.Name,
			TextColor3 = if props.IsDisabled then Color3.fromRGB(150, 150, 150) else Color3.new(1, 1, 1),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, {
			uIAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 6.11364,
			}),

			uIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.0909091, 0),
				PaddingTop = UDim.new(0.0909091, 0),
			}),
		}),

		sliderContainer = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.65, 0), -- Center vertically by filling container
			Size = UDim2.fromScale(0.33, 1),
			ref = sliderRef,
			[React.Event.InputBegan] = function(_, input)
				if props.IsDisabled then
					return
				end
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					setIsDragging(true)
					updateSlider(input)
				end
			end,
		}, {
			track = e("Frame", {
				AnchorPoint = Vector2.new(0, 0.5), -- Center track vertically
				Position = UDim2.fromScale(0, 0.5),
				BackgroundColor3 = Color3.fromRGB(40, 45, 80),
				Size = UDim2.fromScale(1, 0.3), -- Track is thinner than hit area
				BorderSizePixel = 0,
				ClipsDescendants = true,
			}, {
				UICorner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
				UIStroke = e("UIStroke", {
					Color = Color3.new(1, 1, 1),
					Thickness = 1,
					Transparency = 0.5,
				}),

				fill = e("Frame", {
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

			handle = e("Frame", {
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

		valueLabel = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
			Position = UDim2.fromScale(0.58, 0.28),
			Size = UDim2.fromScale(0.06, 0.44),
			Text = tostring(math.round(progress * 100)),
			TextColor3 = if props.IsDisabled then Color3.fromRGB(150, 150, 150) else Color3.new(1, 1, 1),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Right,
		}),
	})
end
