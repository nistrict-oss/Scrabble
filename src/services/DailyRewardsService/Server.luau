local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Networker = require(ReplicatedStorage.Packages.Networker)
local DataService = require(ReplicatedStorage.Packages.DataService).server
local DailyRewards = require(ReplicatedStorage.Shared.Modules.Game.DailyRewards)

-- Lazy-loaded analytics
local AnalyticsService
task.defer(function()
	AnalyticsService = require(ServerScriptService.Services.AnalyticsService.AnalyticsServiceServer)
end)

local DailyRewardsServiceServer = {
	Networker = nil,
	CurrencyService = nil,
	InventoryService = nil,
}

export type DailyRewardsServiceServer = typeof(DailyRewardsServiceServer) & {
	Networker: Networker.Server,
}

function DailyRewardsServiceServer.init(self: DailyRewardsServiceServer, services)
	self.CurrencyService = services.CurrencyService
	self.InventoryService = services.InventoryService
	
	-- Third argument is whitelist of network-callable functions
	self.Networker = Networker.server.new("DailyRewardsService", self, {
		self.GetDailyRewardStatus,
		self.ClaimDailyReward,
	})
end

function DailyRewardsServiceServer.GetDailyRewardStatus(self: DailyRewardsServiceServer, player: Player)
	DataService:waitForData(player)
	
	if not DataService:hasProfile(player) then
		self.Networker:fire({ player }, "StatusLoaded", { streak = 1, canClaim = false, timeRemaining = 0 })
		return
	end
	
	local lastClaim = DataService:get(player, { "LastDailyRewardClaim" }) or 0
	local streak = DataService:get(player, { "DailyRewardStreak" }) or 0
	
	-- Check if streak should reset (missed more than 48 hours)
	if lastClaim > 0 and DailyRewards.shouldResetStreak(lastClaim) then
		streak = 0
	end
	
	local canClaim = DailyRewards.canClaim(lastClaim)
	local timeRemaining = DailyRewards.getTimeUntilNextClaim(lastClaim)
	
	local status = {
		streak = streak + 1, -- Display as "day X" (1-indexed)
		canClaim = canClaim,
		timeRemaining = timeRemaining,
	}
	
	self.Networker:fire({ player }, "StatusLoaded", status)
end

function DailyRewardsServiceServer.ClaimDailyReward(self: DailyRewardsServiceServer, player: Player)
	DataService:waitForData(player)
	
	if not DataService:hasProfile(player) then
		self.Networker:fire({ player }, "RewardClaimed", false, nil)
		return
	end
	
	local lastClaim = DataService:get(player, { "LastDailyRewardClaim" }) or 0
	local streak = DataService:get(player, { "DailyRewardStreak" }) or 0
	
	-- Check if can claim
	if not DailyRewards.canClaim(lastClaim) then
		self.Networker:fire({ player }, "RewardClaimed", false, nil)
		return
	end
	
	-- Check if streak should reset
	if lastClaim > 0 and DailyRewards.shouldResetStreak(lastClaim) then
		streak = 0
	end
	
	-- Increment streak
	streak = streak + 1
	
	-- Get reward for current day
	local reward = DailyRewards.getRewardForDay(streak)
	
	-- Give reward
	if reward.type == "cash" then
		if self.CurrencyService then
			self.CurrencyService:addCash(player, reward.amount)
		end
	elseif reward.type == "luckyspin" then
		if self.InventoryService and self.InventoryService.addLuckySpins then
			self.InventoryService:addLuckySpins(player, reward.amount)
		end
	end
	
	-- Check for bonus reward (day 7)
	if reward.bonus then
		if reward.bonus.type == "luckyspin" then
			if self.InventoryService and self.InventoryService.addLuckySpins then
				self.InventoryService:addLuckySpins(player, reward.bonus.amount)
			end
		elseif reward.bonus.type == "cash" then
			if self.CurrencyService then
				self.CurrencyService:addCash(player, reward.bonus.amount)
			end
		end
	end
	
	-- Update data
	DataService:set(player, { "DailyRewardStreak" }, streak)
	DataService:set(player, { "LastDailyRewardClaim" }, os.time())
	
	print("[DailyRewards] " .. player.Name .. " claimed day " .. streak .. " reward: " .. reward.label)
	
	-- Track daily reward claim
	if AnalyticsService then
		AnalyticsService:trackDailyRewardClaimed(player, streak)
	end
	
	self.Networker:fire({ player }, "RewardClaimed", true, reward)
end

return DailyRewardsServiceServer
