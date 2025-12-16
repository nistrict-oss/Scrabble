local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- DataService from package (must init first)
local DataService = require(ReplicatedStorage.Packages.DataService).server
local DataTemplate = require(ReplicatedStorage.Shared.Modules.Core.DataTemplate)
local ScrabbleDictionary = require(ReplicatedStorage.Shared.Modules.Game.ScrabbleDictionary)

DataService:init({
	template = DataTemplate,
	profileStoreIndex = "Production",
	-- useMock = true, -- Uncomment for testing without saving
})

-- Analytics (init early to track everything)
local AnalyticsServiceServer = require(ServerScriptService.Services.AnalyticsService.AnalyticsServiceServer)

-- Custom services
local CurrencyServiceServer = require(ServerScriptService.Services.CurrencyService.CurrencyServiceServer)
local StatsServiceServer = require(ServerScriptService.Services.StatsService.StatsServiceServer)
local SettingsServiceServer = require(ServerScriptService.Services.SettingsService.SettingsServiceServer)
local InventoryServiceServer = require(ServerScriptService.Services.InventoryService.InventoryServiceServer)
local PurchaseServiceServer = require(ServerScriptService.Services.PurchaseService.PurchaseServiceServer)
local TasksServiceServer = require(ServerScriptService.Services.TasksService.TasksServiceServer)
local StreakServiceServer = require(ServerScriptService.Services.StreakService.StreakServiceServer)
local CodesServiceServer = require(ServerScriptService.Services.CodesService.CodesServiceServer)
local DailyRewardsServiceServer = require(ServerScriptService.Services.DailyRewardsService.DailyRewardsServiceServer)
local LeaderboardServiceServer = require(ServerScriptService.Services.LeaderboardService.LeaderboardServiceServer)
local ChatTagServiceServer = require(ServerScriptService.Services.ChatTagService.ChatTagServiceServer)
local PolicyServiceServer = require(ServerScriptService.Services.PolicyService.PolicyServiceServer)

-- Game services
local ScrabbleServiceServer = require(ServerScriptService.Services.ScrabbleService.ScrabbleServiceServer)

-- Initialize analytics first
AnalyticsServiceServer:init()

-- Initialize custom services
CurrencyServiceServer:init()
StatsServiceServer:init()
SettingsServiceServer:init()
PurchaseServiceServer:init()
TasksServiceServer:init()
StreakServiceServer:init()
CodesServiceServer:init()
DailyRewardsServiceServer:init({
	CurrencyService = CurrencyServiceServer,
	InventoryService = InventoryServiceServer,
})
LeaderboardServiceServer:init()
ChatTagServiceServer:init()
PolicyServiceServer:init()
ScrabbleDictionary:init()

-- Initialize game services
ScrabbleServiceServer:init()
