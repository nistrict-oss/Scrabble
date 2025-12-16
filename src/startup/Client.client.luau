local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local React_Roblox = require(ReplicatedStorage.Packages["React-Roblox"])

-- DataService from package (must init first - yields until data loaded)
print("[Client] Initializing DataService...")
local DataService = require(ReplicatedStorage.Packages.DataService).client
DataService:init()
print("[Client] DataService initialized")

-- Custom services
local CurrencyServiceClient = require(ReplicatedStorage.Shared.Services.CurrencyService.CurrencyServiceClient)
local StatsServiceClient = require(ReplicatedStorage.Shared.Services.StatsService.StatsServiceClient)
local SettingsServiceClient = require(ReplicatedStorage.Shared.Services.SettingsService.SettingsServiceClient)
local PurchaseServiceClient = require(ReplicatedStorage.Shared.Services.PurchaseService.PurchaseServiceClient)
local TasksServiceClient = require(ReplicatedStorage.Shared.Services.TasksService.TasksServiceClient)
local CodesServiceClient = require(ReplicatedStorage.Shared.Services.CodesService.CodesServiceClient)
local DailyRewardsServiceClient = require(ReplicatedStorage.Shared.Services.DailyRewardsService.DailyRewardsServiceClient)
local LeaderboardServiceClient = require(ReplicatedStorage.Shared.Services.LeaderboardService.LeaderboardServiceClient)
local ChatTagServiceClient = require(ReplicatedStorage.Shared.Services.ChatTagService.ChatTagServiceClient)
local PolicyServiceClient = require(ReplicatedStorage.Shared.Services.PolicyService.PolicyServiceClient)

local ScrabbleServiceClient = require(ReplicatedStorage.Shared.Services.ScrabbleService.ScrabbleServiceClient)


local App = require(ReplicatedStorage.UI.App)

-- Initialize custom services
CurrencyServiceClient:init()
StatsServiceClient:init()
SettingsServiceClient:init()
PurchaseServiceClient:init()
TasksServiceClient:init()
CodesServiceClient:init()
DailyRewardsServiceClient:init()
LeaderboardServiceClient:init()
ChatTagServiceClient:init()
PolicyServiceClient:init()

-- Initialize game service
ScrabbleServiceClient:init()


local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

print("[Client] Rendering UI...")
local root = React_Roblox.createRoot(PlayerGui)
root:render(React.createElement(App))
print("[Client] UI rendered successfully")