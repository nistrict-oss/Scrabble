--[[
	AnimatedModal.luau
	
	Reusable animated modal wrapper that provides smooth scale-in/out animations
	with backdrop fade effect for popup panels.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

-- Animation constants
local TWEEN_DURATION = 0.4
local TWEEN_INFO_IN = TweenInfo.new(TWEEN_DURATION, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_INFO_OUT = TweenInfo.new(TWEEN_DURATION * 0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

export type AnimatedModalProps = {
	Visible: boolean,
	OnClose: (() -> ())?,
	Size: UDim2?, -- Size of the content container (default: 0.75, 0.75)
	ZIndex: number?,
	ShowBackdrop: boolean?, -- Whether to show dimmed backdrop (default: true)
	BackdropTransparency: number?, -- Target backdrop transparency (default: 0.4)
	children: any,
}

local function AnimatedModal(props: AnimatedModalProps)
	local visible = props.Visible
	local size = props.Size or UDim2.fromScale(0.75, 0.75)
	local zIndex = props.ZIndex or 100
	local showBackdrop = if props.ShowBackdrop == nil then true else props.ShowBackdrop
	local backdropTransparency = props.BackdropTransparency or 0.4

	-- Animation state
	local isShowing, setIsShowing = React.useState(false)
	local containerRef = React.useRef(nil :: Frame?)
	local backdropRef = React.useRef(nil :: Frame?)

	-- Animation effect - tween in/out when visibility changes
	React.useEffect(function()
		local container = containerRef.current
		local backdrop = backdropRef.current

		if visible then
			-- Show panel with animation
			setIsShowing(true)

			-- Wait for refs to be available
			task.defer(function()
				container = containerRef.current
				backdrop = backdropRef.current

				if container then
					-- Start from scaled down
					container.Size = UDim2.fromScale(0, 0)
					container.Position = UDim2.fromScale(0.5, 0.5)

					-- Animate to full size
					local tween = TweenService:Create(container, TWEEN_INFO_IN, {
						Size = size,
					})
					tween:Play()
				end

				if backdrop and showBackdrop then
					backdrop.BackgroundTransparency = 1
					TweenService:Create(backdrop, TWEEN_INFO_IN, {
						BackgroundTransparency = backdropTransparency,
					}):Play()
				end
			end)
		else
			-- Animate out (use task.defer to ensure refs are available)
			task.defer(function()
				local closeContainer = containerRef.current
				local closeBackdrop = backdropRef.current

				if closeContainer then
					local tween = TweenService:Create(closeContainer, TWEEN_INFO_OUT, {
						Size = UDim2.fromScale(0, 0),
					})

					if closeBackdrop and showBackdrop then
						TweenService:Create(closeBackdrop, TWEEN_INFO_OUT, {
							BackgroundTransparency = 1,
						}):Play()
					end

					tween.Completed:Connect(function()
						setIsShowing(false)
					end)
					tween:Play()
				else
					setIsShowing(false)
				end
			end)
		end
	end, { visible })

	return e("Frame", {
		Visible = visible or isShowing, -- Keep visible during exit animation
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,
		ZIndex = zIndex,
		Active = visible or isShowing, -- Block input to things behind
	}, {
		-- Dimmed backdrop
		Backdrop = showBackdrop
				and e("Frame", {
					ref = backdropRef,
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 1, -- Starts transparent, animates in
					ZIndex = zIndex,
				})
			or nil,

		-- Animated container for the content
		AnimatedContainer = e("Frame", {
			ref = containerRef,
			Size = size,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			ZIndex = zIndex + 1,
		}, props.children),
	})
end

return AnimatedModal
