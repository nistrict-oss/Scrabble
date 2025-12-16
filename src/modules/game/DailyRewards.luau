-- Daily Rewards configuration
-- 7-day cycle that repeats

local DailyRewards = {}

-- Reward types: "cash", "luckyspin"
DailyRewards.REWARDS = {
	[1] = { type = "cash", amount = 500, icon = "💵", label = "500 Cash" },
	[2] = { type = "cash", amount = 750, icon = "💵", label = "750 Cash" },
	[3] = { type = "cash", amount = 1000, icon = "💵", label = "1,000 Cash" },
	[4] = { type = "luckyspin", amount = 1, icon = "🍀", label = "1 Lucky Spin" },
	[5] = { type = "cash", amount = 1500, icon = "💵", label = "1,500 Cash" },
	[6] = { type = "cash", amount = 2000, icon = "💵", label = "2,000 Cash" },
	[7] = { type = "cash", amount = 3000, icon = "🎁", label = "3,000 Cash + Lucky Spin", bonus = { type = "luckyspin", amount = 1 } },
}

DailyRewards.MAX_STREAK = 7 -- After 7, cycle back to day 1 with higher multiplier
DailyRewards.STREAK_MULTIPLIER = 1.5 -- Bonus for completing a full week

-- Time constants (in seconds)
DailyRewards.CLAIM_COOLDOWN = 24 * 60 * 60 -- 24 hours
DailyRewards.STREAK_RESET_TIME = 48 * 60 * 60 -- 48 hours (miss a day = reset streak)

function DailyRewards.getRewardForDay(day: number): typeof(DailyRewards.REWARDS[1])
	-- Cycle through 7 days
	local cycleDay = ((day - 1) % 7) + 1
	return DailyRewards.REWARDS[cycleDay]
end

function DailyRewards.canClaim(lastClaimTime: number): boolean
	local now = os.time()
	return (now - lastClaimTime) >= DailyRewards.CLAIM_COOLDOWN
end

function DailyRewards.shouldResetStreak(lastClaimTime: number): boolean
	local now = os.time()
	return (now - lastClaimTime) >= DailyRewards.STREAK_RESET_TIME
end

function DailyRewards.getTimeUntilNextClaim(lastClaimTime: number): number
	local now = os.time()
	local timePassed = now - lastClaimTime
	local timeRemaining = DailyRewards.CLAIM_COOLDOWN - timePassed
	return math.max(0, timeRemaining)
end

function DailyRewards.formatTime(seconds: number): string
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60
	
	if hours > 0 then
		return string.format("%dh %dm", hours, minutes)
	elseif minutes > 0 then
		return string.format("%dm %ds", minutes, secs)
	else
		return string.format("%ds", secs)
	end
end

return DailyRewards

