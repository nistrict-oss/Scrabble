--[[
	PolicyServiceClient.luau
	
	Client-side policy service for checking regional restrictions.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)

local PolicyServiceClient = {
	Networker = nil,
	
	-- Cached policy info
	Policy = nil :: { ArePaidRandomItemsRestricted: boolean }?,
	
	-- Signals
	OnPolicyLoaded = Signal.new(),
}

export type PolicyServiceClient = typeof(PolicyServiceClient) & {
	Networker: Networker.Client,
}

function PolicyServiceClient.init(self: PolicyServiceClient)
	self.Networker = Networker.client.new("PlayerPolicyService", self)
	
	-- Request policy on init
	task.defer(function()
		self.Networker:fire("GetPolicy")
	end)
end

function PolicyServiceClient.PolicyLoaded(self: PolicyServiceClient, policy: { ArePaidRandomItemsRestricted: boolean })
	self.Policy = policy
	self.OnPolicyLoaded:Fire(policy)
end

-- Check if paid random items are restricted for local player
function PolicyServiceClient.arePaidRandomItemsRestricted(self: PolicyServiceClient): boolean
	if self.Policy then
		return self.Policy.ArePaidRandomItemsRestricted
	end
	-- Default to not restricted until we know for sure
	return false
end

return PolicyServiceClient

