--[[
	ChatTagService/Server.luau
	
	Server-side service for managing chat tags.
	Tracks which players have tags and broadcasts to clients.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Networker = require(ReplicatedStorage.Packages.Networker)

local ChatTagServiceServer = {
	Networker = nil,
	PurchaseService = nil,
	-- Cache of player tags: { [UserId] = { TagText, TagColor } }
	PlayerTags = {},
}

-- Chat tag configurations
local CHAT_TAGS = {
	Supporter = {
		TagText = "[Supporter]",
		TagColor = Color3.fromRGB(255, 215, 0), -- Gold/Yellow
	},
}

function ChatTagServiceServer.init(self: typeof(ChatTagServiceServer))
	self.Networker = Networker.server.new("ChatTagService", self, {
		self.GetPlayerTags,
	})
	
	-- Defer getting PurchaseService to avoid circular dependencies
	task.defer(function()
		pcall(function()
			self.PurchaseService = require(ServerScriptService.Services.PurchaseService.PurchaseServiceServer)
		end)
		
		-- Update tags for all current players
		for _, player in Players:GetPlayers() do
			self:updatePlayerTag(player)
		end
	end)
	
	-- Update tags when players join
	Players.PlayerAdded:Connect(function(player)
		-- Wait a bit for gamepass data to load
		task.delay(2, function()
			self:updatePlayerTag(player)
		end)
	end)
	
	-- Clean up when players leave
	Players.PlayerRemoving:Connect(function(player)
		self.PlayerTags[player.UserId] = nil
	end)
	
	-- Listen for gamepass purchases to update tags
	task.defer(function()
		if self.PurchaseService and self.PurchaseService.OnGamepassPurchased then
			self.PurchaseService.OnGamepassPurchased:Connect(function(player)
				self:updatePlayerTag(player)
			end)
		end
	end)
	
	print("[ChatTagService] Server initialized")
end

function ChatTagServiceServer.updatePlayerTag(self: typeof(ChatTagServiceServer), player: Player)
	if not self.PurchaseService then return end
	
	local oldTag = self.PlayerTags[player.UserId]
	local newTag = nil
	
	-- Check for Supporter tag
	if self.PurchaseService:isSupporter(player) then
		newTag = CHAT_TAGS.Supporter
	end
	
	self.PlayerTags[player.UserId] = newTag
	
	-- Broadcast update if tag changed
	if oldTag ~= newTag then
		self.Networker:fireAll("PlayerTagUpdated", player.UserId, newTag)
	end
end

-- Network handler: Send all player tags to requesting client
function ChatTagServiceServer.GetPlayerTags(self: typeof(ChatTagServiceServer), player: Player)
	self.Networker:fire({ player }, "PlayerTagsLoaded", self.PlayerTags)
end

-- Get tag for a specific player (for external use)
function ChatTagServiceServer.getTag(self: typeof(ChatTagServiceServer), player: Player)
	return self.PlayerTags[player.UserId]
end

return ChatTagServiceServer

