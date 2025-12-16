local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Networker = require(ReplicatedStorage.Packages.Networker)
local DataService = require(ReplicatedStorage.Packages.DataService).server

local StreakServiceServer = {
	Networker = nil,
}

function StreakServiceServer.init(self)
	self.Networker = Networker.server.new("StreakService", self, {
		self.GetAllStreaks,
	})
	
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			DataService:waitForData(player)
			local streak = self:getPlayerStreak(player)
			self.Networker:fireAll("StreakUpdated", player.UserId, streak)
		end)
	end)
end

function StreakServiceServer.getPlayerStreak(_self, player: Player): number
	if not DataService:hasProfile(player) then return 0 end
	return DataService:get(player, { "Stats", "CurrentWinStreak" }) or 0
end

function StreakServiceServer.GetAllStreaks(self, player: Player)
	local streaks = {}
	
	for _, p in ipairs(Players:GetPlayers()) do
		if DataService:hasProfile(p) then
			streaks[p.UserId] = self:getPlayerStreak(p)
		end
	end
	
	self.Networker:fire({ player }, "AllStreaks", streaks)
end

function StreakServiceServer.broadcastStreak(self, player: Player, newStreak: number)
	self.Networker:fireAll("StreakUpdated", player.UserId, newStreak)
end

return StreakServiceServer
