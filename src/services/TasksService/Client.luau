local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)

local TasksServiceClient = {
	Networker = nil :: any,
	Tasks = { Daily = {}, Weekly = {} },
	OnTasksLoaded = Signal.new(),
	OnTaskUpdated = Signal.new(),
	OnTaskClaimed = Signal.new(),
	OnTasksReset = Signal.new(),
}

type TasksServiceClient = typeof(TasksServiceClient)

function TasksServiceClient:getTasks()
	return self.Tasks
end

function TasksServiceClient:getDailyTasks()
	return self.Tasks.Daily
end

function TasksServiceClient:getWeeklyTasks()
	return self.Tasks.Weekly
end

function TasksServiceClient:claimTask(taskId: string, taskType: string)
	return self.Networker:fetch("ClaimTask", taskId, taskType)
end

function TasksServiceClient:refreshTasks()
	local tasks = self.Networker:fetch("GetTasks")
	if tasks then
		self.Tasks = tasks
		self.OnTasksLoaded:Fire(tasks)
	end
end

function TasksServiceClient.TaskUpdated(self: TasksServiceClient, taskId: string, newProgress: number)
	for _, taskType in ipairs({ "Daily", "Weekly" }) do
		for _, task in ipairs(self.Tasks[taskType]) do
			if task.id == taskId then
				task.progress = newProgress
				break
			end
		end
	end
	
	self.OnTaskUpdated:Fire(taskId, newProgress)
end

function TasksServiceClient.TaskClaimed(self: TasksServiceClient, taskId: string, reward: number)
	for _, taskType in ipairs({ "Daily", "Weekly" }) do
		for _, task in ipairs(self.Tasks[taskType]) do
			if task.id == taskId then
				task.claimed = true
				break
			end
		end
	end
	
	self.OnTaskClaimed:Fire(taskId, reward)
end

function TasksServiceClient.TasksReset(self: TasksServiceClient, taskType: string, newTasks: { any })
	self.Tasks[taskType] = newTasks
	self.OnTasksReset:Fire(taskType, newTasks)
end

function TasksServiceClient.init(self: TasksServiceClient)
	self.Networker = Networker.client.new("TasksService", self)
	
	self.Tasks = { Daily = {}, Weekly = {} }
	
	task.spawn(function()
		self:refreshTasks()
	end)
end

return TasksServiceClient
