--[[
	PolicyServiceServer.luau
	
	Handles Roblox PolicyService compliance for regional restrictions.
	Checks ArePaidRandomItemsRestricted for Lucky Spins and similar features.
	
	Reference: https://create.roblox.com/docs/reference/engine/classes/PolicyService#GetPolicyInfoForPlayerAsync
]]

local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)

local PolicyServiceServer = {
	Networker = nil,
	
	-- Cache of player policies
	PlayerPolicies = {} :: { [Player]: { ArePaidRandomItemsRestricted: boolean } },
	
	-- Signals
	OnPolicyLoaded = Signal.new(),
}

export type PolicyServiceServer = typeof(PolicyServiceServer) & {
	Networker: Networker.Server,
}

function PolicyServiceServer.init(self: PolicyServiceServer)
	self.Networker = Networker.server.new("PlayerPolicyService", self, {
		self.GetPolicy,
	})
	
	-- Load policies for existing players
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			self:loadPlayerPolicy(player)
		end)
	end
	
	-- Load policies for new players
	Players.PlayerAdded:Connect(function(player)
		self:loadPlayerPolicy(player)
	end)
	
	-- Clean up when players leave
	Players.PlayerRemoving:Connect(function(player)
		self.PlayerPolicies[player] = nil
	end)
end

function PolicyServiceServer.loadPlayerPolicy(self: PolicyServiceServer, player: Player)
	local success, policyInfo = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	
	if success and policyInfo then
		self.PlayerPolicies[player] = {
			ArePaidRandomItemsRestricted = policyInfo.ArePaidRandomItemsRestricted or false,
		}
		
		-- Send policy info to client
		self.Networker:fire({ player }, "PolicyLoaded", self.PlayerPolicies[player])
		self.OnPolicyLoaded:Fire(player, self.PlayerPolicies[player])
		
		if policyInfo.ArePaidRandomItemsRestricted then
			print(string.format("[PolicyService] Player %s has paid random items restricted", player.Name))
		end
	else
		-- Default to not restricted if we can't get policy info
		self.PlayerPolicies[player] = {
			ArePaidRandomItemsRestricted = false,
		}
		self.Networker:fire({ player }, "PolicyLoaded", self.PlayerPolicies[player])
		
		if not success then
			warn(string.format("[PolicyService] Failed to get policy for %s: %s", player.Name, tostring(policyInfo)))
		end
	end
end

-- Check if paid random items are restricted for a player
function PolicyServiceServer.arePaidRandomItemsRestricted(self: PolicyServiceServer, player: Player): boolean
	local policy = self.PlayerPolicies[player]
	if policy then
		return policy.ArePaidRandomItemsRestricted
	end
	-- Default to restricted if we don't have policy info yet (safer)
	return true
end

-- Network handler for client requesting policy
function PolicyServiceServer.GetPolicy(self: PolicyServiceServer, player: Player)
	local policy = self.PlayerPolicies[player]
	if policy then
		self.Networker:fire({ player }, "PolicyLoaded", policy)
	else
		-- Policy not loaded yet, load it now
		self:loadPlayerPolicy(player)
	end
end

return PolicyServiceServer

