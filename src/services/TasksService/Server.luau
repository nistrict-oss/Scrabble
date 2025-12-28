local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)
local DataService = require(ReplicatedStorage.Packages.DataService).server

local TASK_DEFINITIONS = {
	-- DAILY TASKS (Total: ~400 cash if all completed)
	play_games = { name = "Play Games", icon = "🎮", type = "Daily", baseGoal = 3, baseReward = 75 },
	win_game = { name = "Win a Game", icon = "🏆", type = "Daily", baseGoal = 1, baseReward = 150 },
	answer_questions = { name = "Answer Questions", icon = "❓", type = "Daily", baseGoal = 10, baseReward = 50 },
	eliminate_players = { name = "Eliminate Players", icon = "💥", type = "Daily", baseGoal = 5, baseReward = 100 },
	-- WEEKLY TASKS (Total: ~1800 cash if all completed)
	weekly_wins = { name = "Win Games", icon = "👑", type = "Weekly", baseGoal = 10, baseReward = 750 },
	weekly_rounds = { name = "Play Rounds", icon = "🔄", type = "Weekly", baseGoal = 50, baseReward = 500 },
	weekly_correct = { name = "Answer Correctly", icon = "✅", type = "Weekly", baseGoal = 100, baseReward = 600 },
}

local TASK_TYPE_TO_KEY = {
	Daily = "DailyTasks",
	Weekly = "WeeklyTasks",
}

local TasksServiceServer = {
	Networker = nil :: any,
	DataService = nil :: any,
	CurrencyService = nil :: any,
	PurchaseService = nil :: any,
	OnTaskCompleted = nil :: any,
	OnTaskClaimed = nil :: any,
}

type TasksServiceServer = typeof(TasksServiceServer)

function TasksServiceServer.GetTasks(self: TasksServiceServer, player: Player)
	self.DataService:waitForData(player)

	if not self.DataService:hasProfile(player) then
		return { Daily = {}, Weekly = {} }
	end

	local data = self.DataService:get(player)
	local dailyTasks = data and data.DailyTasks or {}
	local weeklyTasks = data and data.WeeklyTasks or {}

	if #dailyTasks == 0 then
		dailyTasks = self:generateDailyTasks()
		self.DataService:set(player, { "DailyTasks" }, dailyTasks)
	end

	if #weeklyTasks == 0 then
		weeklyTasks = self:generateWeeklyTasks()
		self.DataService:set(player, { "WeeklyTasks" }, weeklyTasks)
	end

	return { Daily = dailyTasks, Weekly = weeklyTasks }
end

function TasksServiceServer.ClaimTask(self: TasksServiceServer, player: Player, taskId: string, taskType: string)
	if not self.DataService:hasProfile(player) then
		return false
	end

	local dataKey = TASK_TYPE_TO_KEY[taskType]
	if not dataKey then
		return false
	end

	local data = self.DataService:get(player)
	local tasks = data[dataKey]

	if not tasks then
		return false
	end

	for i, task in ipairs(tasks) do
		if task.id == taskId and task.progress >= task.goal and not task.claimed then
			task.claimed = true
			self.DataService:set(player, { dataKey, i }, task)

			-- Apply Supporter 2x cash multiplier
			local multiplier = if self.PurchaseService then self.PurchaseService:getCoinsMultiplier(player) else 1
			local actualReward = task.reward * multiplier

			self.CurrencyService:addCoins(player, actualReward)

			self.OnTaskClaimed:Fire(player, taskId)
			self.Networker:fire(player, "TaskClaimed", taskId, actualReward)

			return true
		end
	end

	return false
end

function TasksServiceServer:generateDailyTasks()
	local tasks = {}
	local dailyTaskIds = { "play_games", "win_game", "answer_questions", "eliminate_players" }

	for _, taskId in ipairs(dailyTaskIds) do
		local def = TASK_DEFINITIONS[taskId]
		if def then
			table.insert(tasks, {
				id = taskId,
				name = def.name,
				icon = def.icon,
				progress = 0,
				goal = def.baseGoal,
				reward = def.baseReward,
				claimed = false,
			})
		end
	end

	return tasks
end

function TasksServiceServer:generateWeeklyTasks()
	local tasks = {}
	local weeklyTaskIds = { "weekly_wins", "weekly_rounds", "weekly_correct" }

	for _, taskId in ipairs(weeklyTaskIds) do
		local def = TASK_DEFINITIONS[taskId]
		if def then
			table.insert(tasks, {
				id = taskId,
				name = def.name,
				icon = def.icon,
				progress = 0,
				goal = def.baseGoal,
				reward = def.baseReward,
				claimed = false,
			})
		end
	end

	return tasks
end

function TasksServiceServer:incrementTask(player: Player, taskId: string, amount: number?)
	amount = amount or 1

	if not self.DataService:hasProfile(player) then
		return
	end

	local data = self.DataService:get(player)

	for _taskType, dataKey in pairs(TASK_TYPE_TO_KEY) do
		local tasks = data[dataKey]
		if tasks then
			for i, task in ipairs(tasks) do
				if task.id == taskId and not task.claimed then
					local newProgress = math.min(task.progress + amount, task.goal)
					task.progress = newProgress
					self.DataService:set(player, { dataKey, i }, task)

					self.Networker:fire(player, "TaskUpdated", taskId, newProgress)

					if newProgress >= task.goal then
						self.OnTaskCompleted:Fire(player, taskId)
					end

					return
				end
			end
		end
	end
end

function TasksServiceServer:resetDailyTasks(player: Player)
	if not self.DataService:hasProfile(player) then
		return
	end

	local newTasks = self:generateDailyTasks()
	self.DataService:set(player, { "DailyTasks" }, newTasks)
	self.Networker:fire(player, "TasksReset", "Daily", newTasks)
end

function TasksServiceServer:resetWeeklyTasks(player: Player)
	if not self.DataService:hasProfile(player) then
		return
	end

	local newTasks = self:generateWeeklyTasks()
	self.DataService:set(player, { "WeeklyTasks" }, newTasks)
	self.Networker:fire(player, "TasksReset", "Weekly", newTasks)
end

function TasksServiceServer.init(self: TasksServiceServer)
	self.Networker = Networker.server.new("TasksService", self, {
		self.GetTasks,
		self.ClaimTask,
	})

	self.DataService = DataService
	task.defer(function()
		self.CurrencyService = require(ServerScriptService.Services.CurrencyService.CurrencyServiceServer)
		self.PurchaseService = require(ServerScriptService.Services.PurchaseService.PurchaseServiceServer)
	end)

	self.OnTaskCompleted = Signal.new()
	self.OnTaskClaimed = Signal.new()
end

return TasksServiceServer
