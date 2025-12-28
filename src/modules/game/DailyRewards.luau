-- Daily Rewards configuration
-- 7-day cycle that repeats

local DailyRewards = {}

local COIN_ICON = "rbxassetid://76014729251663"

-- Reward types: "coins"
DailyRewards.REWARDS = {
	[1] = { type = "coins", amount = 500, icon = COIN_ICON, label = "500 Coins" },
	[2] = { type = "coins", amount = 750, icon = COIN_ICON, label = "750 Coins" },
	[3] = { type = "coins", amount = 1000, icon = COIN_ICON, label = "1,000 Coins" },
	[4] = { type = "coins", amount = 1250, icon = COIN_ICON, label = "1,250 Coins" },
	[5] = { type = "coins", amount = 1500, icon = COIN_ICON, label = "1,500 Coins" },
	[6] = { type = "coins", amount = 2000, icon = COIN_ICON, label = "2,000 Coins" },
	[7] = {
		type = "coins",
		amount = 5000,
		icon = COIN_ICON,
		label = "5,000 Coins",
		-- No bonus logic needed for now if it's just a big coin drop
	},
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
