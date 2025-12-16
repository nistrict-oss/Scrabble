local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)

type Stats = {
	GamesPlayed: number?,
	Wins: number?,
	QuestionsAnswered: number?,
	CorrectAnswers: number?,
	Eliminations: number?,
	TimePlayed: number?,
	CashEarned: number?,
	CurrentWinStreak: number?,
	HighestStreak: number?,
	[string]: number?,
}

local StatsServiceClient = {
	Networker = nil :: any,
	Stats = {} :: Stats,
	
	OnStatsLoaded = Signal.new(),
	OnStatUpdated = Signal.new(),
}

export type StatsServiceClient = typeof(StatsServiceClient) & {
	Networker: Networker.Client,
}

function StatsServiceClient.init(self: StatsServiceClient)
	self.Networker = Networker.client.new("StatsService", self)
	
	task.defer(function()
		self.Networker:fire("GetStats")
	end)
end

function StatsServiceClient.StatsLoaded(self: StatsServiceClient, stats: any)
	self.Stats = stats or {}
	self.OnStatsLoaded:Fire(self.Stats)
end

function StatsServiceClient.StatUpdated(self: StatsServiceClient, statName: string, value: number)
	local newStats = table.clone(self.Stats)
	newStats[statName] = value
	self.Stats = newStats
	self.OnStatUpdated:Fire(statName, value, newStats)
end

function StatsServiceClient.getStats(self: StatsServiceClient): any
	return table.clone(self.Stats)
end

function StatsServiceClient.getStat(self: StatsServiceClient, statName: string): number
	return self.Stats[statName] or 0
end

function StatsServiceClient.getWinRate(self: StatsServiceClient): number
	local gamesPlayed = self.Stats.GamesPlayed or 0
	local wins = self.Stats.Wins or 0
	
	if gamesPlayed == 0 then return 0 end
	return math.floor((wins / gamesPlayed) * 100)
end

function StatsServiceClient.getAccuracy(self: StatsServiceClient): number
	local answered = self.Stats.QuestionsAnswered or 0
	local correct = self.Stats.CorrectAnswers or 0
	
	if answered == 0 then return 0 end
	return math.floor((correct / answered) * 100)
end

return StatsServiceClient
