--[[
	ChatTagService/Client.luau
	
	Client-side service for displaying chat tags.
	Uses TextChatService.OnIncomingMessage to add tags to messages.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local Networker = require(ReplicatedStorage.Packages.Networker)

local ChatTagServiceClient = {
	Networker = nil,
	-- Cache of player tags: { [UserId] = { TagText, TagColor } }
	PlayerTags = {},
}

function ChatTagServiceClient.init(self: typeof(ChatTagServiceClient))
	self.Networker = Networker.client.new("ChatTagService", self)
	
	-- Request tags from server
	task.defer(function()
		self.Networker:fire("GetPlayerTags")
	end)
	
	-- Set up chat message callback
	TextChatService.OnIncomingMessage = function(message: TextChatMessage)
		return self:onIncomingMessage(message)
	end
	
	print("[ChatTagService] Client initialized")
end

function ChatTagServiceClient.PlayerTagsLoaded(self: typeof(ChatTagServiceClient), tags: { [number]: any })
	self.PlayerTags = tags or {}
end

function ChatTagServiceClient.PlayerTagUpdated(self: typeof(ChatTagServiceClient), userId: number, tagInfo: any?)
	self.PlayerTags[userId] = tagInfo
end

function ChatTagServiceClient.onIncomingMessage(self: typeof(ChatTagServiceClient), message: TextChatMessage): TextChatMessageProperties
	local properties = Instance.new("TextChatMessageProperties")
	
	-- Get the source player
	local textSource = message.TextSource
	if not textSource then
		return properties
	end
	
	local userId = textSource.UserId
	local tag = self.PlayerTags[userId]
	
	if tag then
		-- Format: <font color="#RRGGBB">[Supporter]</font> Username: Message
		local hexColor = string.format("#%02X%02X%02X", 
			math.floor(tag.TagColor.R * 255),
			math.floor(tag.TagColor.G * 255),
			math.floor(tag.TagColor.B * 255)
		)
		properties.PrefixText = string.format('<font color="%s">%s</font> %s', 
			hexColor, 
			tag.TagText,
			message.PrefixText or ""
		)
	end
	
	return properties
end

-- Get tag for a specific player
function ChatTagServiceClient.getTag(self: typeof(ChatTagServiceClient), player: Player)
	return self.PlayerTags[player.UserId]
end

-- Check if a player has a tag
function ChatTagServiceClient.hasTag(self: typeof(ChatTagServiceClient), player: Player): boolean
	return self.PlayerTags[player.UserId] ~= nil
end

return ChatTagServiceClient

