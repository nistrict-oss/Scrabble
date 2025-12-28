local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.React)
local StyledPanel = require(ReplicatedStorage.UI.components.frames.StyledPanel)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)
local DailyRewards = require(ReplicatedStorage.Shared.Modules.Game.DailyRewards)
local SoundUtils = require(ReplicatedStorage.Shared.Modules.Core.SoundUtils)

local e = React.createElement

-- Animation constants
local TWEEN_DURATION = 0.4
local TWEEN_INFO_IN = TweenInfo.new(TWEEN_DURATION, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_INFO_OUT = TweenInfo.new(TWEEN_DURATION * 0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

-- Try to get services (may not exist in Hoarcekat)
local DailyRewardsService
pcall(function()
	DailyRewardsService = require(ReplicatedStorage.Shared.Services.DailyRewardsService.DailyRewardsServiceClient)
end)

local function DailyRewardsPanel(props: {
	Visible: boolean,
	OnClose: () -> (),
	Direction: string?,
})
	local visible = props.Visible
	local onClose = props.OnClose

	-- Animation state
	local isShowing, setIsShowing = React.useState(false)
	local containerRef = React.useRef(nil :: Frame?)
	local backdropRef = React.useRef(nil :: Frame?)

	-- State
	local currentStreak, setCurrentStreak = React.useState(1)
	local canClaim, setCanClaim = React.useState(true)
	local timeUntilClaim, setTimeUntilClaim = React.useState(0)
	local claiming, setClaiming = React.useState(false)
	local claimed, setClaimed = React.useState(false)

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
					-- Start from scaled down and transparent
					container.Size = UDim2.fromScale(0, 0)
					container.Position = UDim2.fromScale(0.5, 0.5)

					-- Animate to full size
					local tween = TweenService:Create(container, TWEEN_INFO_IN, {
						Size = UDim2.fromScale(0.75, 0.75),
					})
					tween:Play()
				end

				if backdrop then
					backdrop.BackgroundTransparency = 1
					TweenService:Create(backdrop, TWEEN_INFO_IN, {
						BackgroundTransparency = 0.4,
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

					if closeBackdrop then
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

	React.useEffect(function()
		-- Get cached status if available
		if DailyRewardsService and DailyRewardsService.getDailyRewardStatus then
			local status = DailyRewardsService:getDailyRewardStatus()
			if status then
				setCurrentStreak(status.streak or 1)
				setCanClaim(status.canClaim)
				setTimeUntilClaim(status.timeRemaining or 0)
			end
		end

		-- Listen for status updates
		local connections = {}
		if DailyRewardsService then
			if DailyRewardsService.OnStatusUpdated then
				table.insert(
					connections,
					DailyRewardsService.OnStatusUpdated:Connect(function(status)
						if status then
							setCurrentStreak(status.streak or 1)
							setCanClaim(status.canClaim)
							setTimeUntilClaim(status.timeRemaining or 0)
						end
					end)
				)
			end

			if DailyRewardsService.OnRewardClaimed then
				table.insert(
					connections,
					DailyRewardsService.OnRewardClaimed:Connect(function(reward)
						setClaimed(true)
						setClaiming(false)
						setCurrentStreak(function(prev)
							return prev + 1
						end)

						-- Close after showing success
						task.delay(1.5, function()
							if onClose then
								onClose()
							end
						end)
					end)
				)
			end
		end

		return function()
			for _, conn in connections do
				conn:Disconnect()
			end
		end
	end, {})

	-- Timer countdown
	React.useEffect(function()
		if not canClaim and timeUntilClaim > 0 then
			local running = true
			task.spawn(function()
				while running and timeUntilClaim > 0 do
					task.wait(1)
					setTimeUntilClaim(function(prev)
						local newTime = prev - 1
						if newTime <= 0 then
							setCanClaim(true)
							return 0
						end
						return newTime
					end)
				end
			end)
			return function()
				running = false
			end
		end
		return nil
	end, { canClaim })

	-- Claim handler
	local function handleClaim()
		if not canClaim or claiming or claimed then
			return
		end

		setClaiming(true)

		-- Play claim sound (respects SFX settings)
		SoundUtils.playPurchaseSuccess()

		-- Send claim request to server (response handled via OnRewardClaimed signal)
		if DailyRewardsService and DailyRewardsService.claimDailyReward then
			DailyRewardsService:claimDailyReward()
		else
			-- Fallback for testing (no service available)
			setClaimed(true)
			setClaiming(false)
			task.delay(1.5, function()
				if onClose then
					onClose()
				end
			end)
		end
	end

	-- Build day cards
	local dayCards = {}
	for day = 1, 7 do
		local reward = DailyRewards.getRewardForDay(day)
		local isCurrentDay = ((currentStreak - 1) % 7) + 1 == day
		local isPastDay = ((currentStreak - 1) % 7) + 1 > day

		local cardColor = if isPastDay
			then Color3.fromRGB(60, 70, 60)
			elseif isCurrentDay then Color3.fromRGB(80, 100, 140)
			else Color3.fromRGB(40, 45, 55)

		local borderColor = if isCurrentDay
			then Color3.fromRGB(100, 180, 255)
			elseif isPastDay then Color3.fromRGB(100, 200, 100)
			else Color3.fromRGB(60, 65, 75)

		dayCards["Day" .. day] = e("Frame", {
			Size = UDim2.fromScale(0.13, 1),
			BackgroundColor3 = cardColor,
			BorderSizePixel = 0,
			LayoutOrder = day,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0.08, 0) }),
			UIStroke = e("UIStroke", {
				Color = borderColor,
				Thickness = isCurrentDay and 3 or 2,
			}),

			-- Day number
			DayLabel = e("TextLabel", {
				Size = UDim2.fromScale(1, 0.18),
				Position = UDim2.fromScale(0.5, 0.06),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Text = "Day " .. day,
				Font = Enum.Font.GothamBold,
				TextScaled = true,
				TextColor3 = isCurrentDay and Color3.fromRGB(100, 180, 255) or Color3.fromRGB(180, 180, 190),
			}),

			-- Reward icon
			Icon = isPastDay and e("TextLabel", {
				Size = UDim2.fromScale(0.7, 0.35),
				Position = UDim2.fromScale(0.5, 0.48),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Text = "✓",
				Font = Enum.Font.GothamBold,
				TextScaled = true,
				TextColor3 = Color3.fromRGB(100, 200, 100),
			}) or e("ImageLabel", {
				Size = UDim2.fromScale(0.7, 0.35),
				Position = UDim2.fromScale(0.5, 0.48),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = reward.icon,
				ScaleType = Enum.ScaleType.Fit,
			}),

			-- Reward label
			RewardLabel = e("TextLabel", {
				Size = UDim2.fromScale(0.95, 0.22),
				Position = UDim2.fromScale(0.5, 0.82),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Text = reward.label,
				Font = Enum.Font.GothamMedium,
				TextScaled = true,
				TextColor3 = Color3.fromRGB(200, 200, 210),
			}),

			-- Current day glow
			Glow = isCurrentDay and e("Frame", {
				Size = UDim2.fromScale(1.08, 1.08),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(100, 180, 255),
				BackgroundTransparency = 0.85,
				ZIndex = 0,
			}, {
				UICorner = e("UICorner", { CornerRadius = UDim.new(0.08, 0) }),
			}) or nil,
		})
	end

	-- Main Modal Implementation
	return e("Frame", {
		Visible = visible or isShowing, -- Keep visible during exit animation
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,
		ZIndex = 100, -- High ZIndex for modal overlay
		Active = visible or isShowing, -- Block input to things behind
	}, {
		-- Dimmed backdrop
		Backdrop = e("Frame", {
			ref = backdropRef,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1, -- Starts transparent, animates in
			ZIndex = 100,
		}),

		-- Animated container for the panel
		AnimatedContainer = e("Frame", {
			ref = containerRef,
			Size = UDim2.fromScale(0.75, 0.75), -- Target size for animation
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			ZIndex = 101,
		}, {
			-- Content Container (The actual panel)
			Container = e(StyledPanel, {
				AspectRatio = 1.6,
				ZIndex = 101,
				Size = UDim2.fromScale(1, 1),
				Children = {
					-- Title Bar
					TitleBar = e("Frame", {
						Size = UDim2.fromScale(1, 0.15),
						BackgroundTransparency = 1,
					}, {
						TitleText = e("TextLabel", {
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
							Text = "🎁 DAILY REWARDS",
							TextColor3 = Color3.new(1, 1, 1),
							Font = Enum.Font.GothamBold,
							TextScaled = true,
						}),
					}),

					-- Close Button
					CloseButton = onClose and e(TextButton, {
						Text = "X",
						Size = UDim2.fromScale(0.1, 0.1),
						Position = UDim2.fromScale(0.95, -0.05),
						AnchorPoint = Vector2.new(1, 0),
						BackgroundColor3 = Color3.fromRGB(200, 60, 60),
						CornerRadius = UDim.new(0.5, 0),
						OnClick = onClose,
						ZIndex = 102,
					}) or nil,

					-- Main Content Area
					Content = e("Frame", {
						Size = UDim2.fromScale(0.9, 0.8),
						Position = UDim2.fromScale(0.5, 0.55),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
					}, {
						-- Streak badge (top right)
						StreakBadge = e("Frame", {
							Size = UDim2.fromScale(0.28, 0.08),
							Position = UDim2.fromScale(0.98, 0.02),
							AnchorPoint = Vector2.new(1, 0),
							BackgroundColor3 = Color3.fromRGB(50, 40, 30),
						}, {
							UICorner = e("UICorner", { CornerRadius = UDim.new(0.4, 0) }),
							UIStroke = e("UIStroke", {
								Color = Color3.fromRGB(255, 150, 50),
								Thickness = 2,
							}),
							Text = e("TextLabel", {
								Size = UDim2.fromScale(0.9, 0.8),
								Position = UDim2.fromScale(0.5, 0.5),
								AnchorPoint = Vector2.new(0.5, 0.5),
								BackgroundTransparency = 1,
								Text = "🔥 " .. currentStreak .. " day streak",
								Font = Enum.Font.GothamBold,
								TextScaled = true,
								TextColor3 = Color3.fromRGB(255, 180, 100),
							}),
						}),

						-- Day cards container
						DaysContainer = e("Frame", {
							Size = UDim2.fromScale(0.98, 0.6),
							Position = UDim2.fromScale(0.5, 0.42),
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundTransparency = 1,
						}, {
							UIListLayout = e("UIListLayout", {
								FillDirection = Enum.FillDirection.Horizontal,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								VerticalAlignment = Enum.VerticalAlignment.Center,
								Padding = UDim.new(0.012, 0),
							}),
						}, dayCards),

						-- Claim button
						ClaimButton = e(TextButton, {
							Size = UDim2.fromScale(0.4, 0.12),
							Position = UDim2.fromScale(0.5, 0.88),
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundColor3 = if claimed
								then Color3.fromRGB(100, 200, 100)
								elseif canClaim then Color3.fromRGB(80, 180, 80)
								else Color3.fromRGB(80, 80, 90),
							Text = if claimed
								then "✓ Claimed!"
								elseif canClaim then "🎁 Claim Reward"
								else "⏰ " .. DailyRewards.formatTime(timeUntilClaim),
							Disabled = not canClaim or claiming or claimed,
							CornerRadius = UDim.new(0.3, 0),
							OnClick = handleClaim,
							ZIndex = 102,
						}),
					}),
				},
			}),
		}),
	})
end

return DailyRewardsPanel
