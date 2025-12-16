local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)
local DataService = require(ReplicatedStorage.Packages.DataService).server

local StreakService
local AnalyticsService

local StatsServiceServer = {
	Networker = nil,
	OnStatUpdated = Signal.new(),
	PlayerJoinTimes = {},
}

export type StatsServiceServer = typeof(StatsServiceServer) & {
	Networker: Networker.Server,
}

function StatsServiceServer.init(self: StatsServiceServer)
	self.Networker = Networker.server.new("StatsService", self, {
		self.GetStats,
	})
	
	-- Lazy load analytics
	task.defer(function()
		AnalyticsService = require(ServerScriptService.Services.AnalyticsService.AnalyticsServiceServer)
	end)
	
	Players.PlayerAdded:Connect(function(player)
		self.PlayerJoinTimes[player] = os.time()
		
		-- Track session start (need to wait for data to check if returning)
		task.spawn(function()
			DataService:waitForData(player)
			if AnalyticsService and DataService:hasProfile(player) then
				local lastJoin = DataService:get(player, { "LastJoin" }) or 0
				local isReturning = lastJoin > 0
				local daysSinceLastVisit = 0
				
				if lastJoin > 0 then
					daysSinceLastVisit = math.floor((os.time() - lastJoin) / 86400)
				end
				
				AnalyticsService:trackSessionStart(player, isReturning, daysSinceLastVisit)
			end
		end)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:saveTimePlayed(player)
		self.PlayerJoinTimes[player] = nil
	end)
	
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in ipairs(Players:GetPlayers()) do
				self:saveTimePlayed(player)
				self.PlayerJoinTimes[player] = os.time()
			end
		end
	end)
	
	for _, player in ipairs(Players:GetPlayers()) do
		if not self.PlayerJoinTimes[player] then
			self.PlayerJoinTimes[player] = os.time()
		end
	end
end

function StatsServiceServer.saveTimePlayed(self: StatsServiceServer, player: Player)
	local joinTime = self.PlayerJoinTimes[player]
	if not joinTime then return end
	
	local sessionTime = os.time() - joinTime
	if sessionTime > 0 then
		self:incrementStat(player, "TimePlayed", sessionTime)
	end
end

function StatsServiceServer.getStats(_self: StatsServiceServer, player: Player): any?
	if not DataService:hasProfile(player) then return nil end
	return DataService:get(player, { "Stats" })
end

function StatsServiceServer.getStat(_self: StatsServiceServer, player: Player, statName: string): number
	if not DataService:hasProfile(player) then return 0 end
	return DataService:get(player, { "Stats", statName }) or 0
end

function StatsServiceServer.incrementStat(self: StatsServiceServer, player: Player, statName: string, amount: number?): number?
	if not DataService:hasProfile(player) then return nil end
	
	amount = amount or 1
	
	local newValue = DataService:update(player, { "Stats", statName }, function(val)
		return (val or 0) + amount
	end)
	
	self.OnStatUpdated:Fire(player, statName, newValue)
	self.Networker:fire({ player }, "StatUpdated", statName, newValue)
	
	return newValue
end

function StatsServiceServer.setStat(self: StatsServiceServer, player: Player, statName: string, value: number)
	if not DataService:hasProfile(player) then return end
	
	DataService:set(player, { "Stats", statName }, value)
	
	self.OnStatUpdated:Fire(player, statName, value)
	self.Networker:fire({ player }, "StatUpdated", statName, value)
end

function StatsServiceServer.updateHighest(self: StatsServiceServer, player: Player, statName: string, value: number)
	local current = self:getStat(player, statName)
	if value > current then
		self:setStat(player, statName, value)
	end
end

function StatsServiceServer.recordGameResult(self: StatsServiceServer, player: Player, won: boolean, kills: number?, questionsAnswered: number?, correctAnswers: number?)
	if not StreakService then
		local success, result = pcall(function()
			return require(ServerScriptService.Services.StreakService.StreakServiceServer)
		end)
		if success then
			StreakService = result
		end
	end
	
	self:incrementStat(player, "GamesPlayed", 1)
	
	local newStreak = 0
	if won then
		self:incrementStat(player, "Wins", 1)
		newStreak = self:incrementStat(player, "CurrentWinStreak", 1) or 0
		if newStreak > 0 then
			self:updateHighest(player, "HighestStreak", newStreak)
		end
	else
		self:incrementStat(player, "Losses", 1)
		self:setStat(player, "CurrentWinStreak", 0)
		newStreak = 0
	end
	
	if StreakService then
		StreakService:broadcastStreak(player, newStreak)
	end
	
	if kills and kills > 0 then
		self:incrementStat(player, "TotalKills", kills)
	end
	
	if questionsAnswered and questionsAnswered > 0 then
		self:incrementStat(player, "QuestionsAnswered", questionsAnswered)
	end
	
	if correctAnswers and correctAnswers > 0 then
		self:incrementStat(player, "CorrectAnswers", correctAnswers)
	end
	
	return newStreak
end

function StatsServiceServer.recordAnswer(self: StatsServiceServer, player: Player, correct: boolean)
	self:incrementStat(player, "QuestionsAnswered", 1)
	if correct then
		self:incrementStat(player, "CorrectAnswers", 1)
	end
end

function StatsServiceServer.recordKill(self: StatsServiceServer, player: Player)
	self:incrementStat(player, "TotalKills", 1)
end

function StatsServiceServer.updateStreak(self: StatsServiceServer, player: Player, currentStreak: number)
	self:updateHighest(player, "HighestStreak", currentStreak)
end

function StatsServiceServer.GetStats(self: StatsServiceServer, player: Player)
	DataService:waitForData(player)
	local stats = self:getStats(player)
	self.Networker:fire({ player }, "StatsLoaded", stats)
end

return StatsServiceServer
