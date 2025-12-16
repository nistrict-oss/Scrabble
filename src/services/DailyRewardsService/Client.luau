local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)

local DailyRewardsServiceClient = {
	Networker = nil,
	
	-- Cached status
	CurrentStatus = nil,
	HasLoadedStatus = false, -- Renamed to avoid conflict with callback
	
	-- Signals
	OnStatusUpdated = Signal.new(),
	OnRewardClaimed = Signal.new(),
}

export type DailyRewardsServiceClient = typeof(DailyRewardsServiceClient) & {
	Networker: Networker.Client,
}

function DailyRewardsServiceClient.init(self: DailyRewardsServiceClient)
	self.Networker = Networker.client.new("DailyRewardsService", self)
	
	-- Fetch initial status
	task.defer(function()
		self:refreshStatus()
	end)
end

function DailyRewardsServiceClient.refreshStatus(self: DailyRewardsServiceClient)
	if self.Networker then
		self.Networker:fire("GetDailyRewardStatus")
	end
end

-- Server callback: receives status
function DailyRewardsServiceClient.StatusLoaded(self: DailyRewardsServiceClient, status)
	self.CurrentStatus = status
	self.HasLoadedStatus = true
	self.OnStatusUpdated:Fire(status)
end

function DailyRewardsServiceClient.getDailyRewardStatus(self: DailyRewardsServiceClient)
	return self.CurrentStatus
end

function DailyRewardsServiceClient.claimDailyReward(self: DailyRewardsServiceClient)
	if self.Networker then
		self.Networker:fire("ClaimDailyReward")
	end
end

-- Server callback: claim result
function DailyRewardsServiceClient.RewardClaimed(self: DailyRewardsServiceClient, success: boolean, reward)
	if success then
		self.OnRewardClaimed:Fire(reward)
		-- Refresh status after claiming
		self:refreshStatus()
	end
end

function DailyRewardsServiceClient.shouldShowPopup(self: DailyRewardsServiceClient): boolean
	-- Wait for status to load (with timeout)
	if not self.HasLoadedStatus then
		local waitStart = os.clock()
		while not self.HasLoadedStatus and (os.clock() - waitStart) < 3 do
			task.wait(0.1)
		end
	end
	
	if self.CurrentStatus then
		return self.CurrentStatus.canClaim
	end
	return false
end

return DailyRewardsServiceClient
