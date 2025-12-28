local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)
local DataService = require(ReplicatedStorage.Packages.DataService).server

-- Lazy-loaded analytics
local AnalyticsService
task.defer(function()
	AnalyticsService = require(ServerScriptService.Services.AnalyticsService.AnalyticsServiceServer)
end)

local SETTINGS_SCHEMA = {
	LobbyMusicVolume = { type = "number", default = 0.5, min = 0, max = 1 },
	GameMusicVolume = { type = "number", default = 0.3, min = 0, max = 1 },
	SFXVolume = { type = "number", default = 0.8, min = 0, max = 1 },
	ShowStreaks = { type = "boolean", default = true },
	ShowTableInfo = { type = "boolean", default = true },
	ShowKeypad = { type = "boolean", default = true },
	ShowTilePoints = { type = "boolean", default = true },
	ConfirmMoves = { type = "boolean", default = false },
	ShowRecentHighlight = { type = "boolean", default = false },
}

local SettingsServiceServer = {
	Networker = nil,
	OnSettingChanged = Signal.new(),
}

export type SettingsServiceServer = typeof(SettingsServiceServer) & {
	Networker: Networker.Server,
}

function SettingsServiceServer.init(self: SettingsServiceServer)
	self.Networker = Networker.server.new("SettingsService", self, {
		self.UpdateSetting,
		self.GetSettings,
		self.ResetSettings,
		self.GetTutorialStatus,
		self.CompleteTutorial,
		self.SkipTutorial,
		self.ResetTutorial,
	})
end

function SettingsServiceServer.validateSetting(
	self: SettingsServiceServer,
	settingName: string,
	value: any
): (boolean, any)
	local schema = SETTINGS_SCHEMA[settingName]
	if not schema then
		return false, nil
	end

	if type(value) ~= schema.type then
		return false, nil
	end

	if schema.type == "number" then
		if schema.min and value < schema.min then
			value = schema.min
		end
		if schema.max and value > schema.max then
			value = schema.max
		end
	end

	return true, value
end

function SettingsServiceServer.getSettings(self: SettingsServiceServer, player: Player): any?
	if not DataService:hasProfile(player) then
		return nil
	end
	return DataService:get(player, { "Settings" })
end

function SettingsServiceServer.getSetting(self: SettingsServiceServer, player: Player, settingName: string): any?
	if not DataService:hasProfile(player) then
		local schema = SETTINGS_SCHEMA[settingName]
		return schema and schema.default
	end

	return DataService:get(player, { "Settings", settingName })
end

function SettingsServiceServer.updateSetting(
	self: SettingsServiceServer,
	player: Player,
	settingName: string,
	value: any
): boolean
	if not DataService:hasProfile(player) then
		return false
	end

	local valid, validatedValue = self:validateSetting(settingName, value)
	if not valid then
		return false
	end

	local oldValue = DataService:get(player, { "Settings", settingName })
	DataService:set(player, { "Settings", settingName }, validatedValue)

	self.OnSettingChanged:Fire(player, settingName, validatedValue, oldValue)
	self.Networker:fire({ player }, "SettingUpdated", settingName, validatedValue)

	-- Track setting changes for important settings
	if AnalyticsService and oldValue ~= validatedValue then
		AnalyticsService:trackSettingChanged(player, settingName, validatedValue)
	end

	return true
end

function SettingsServiceServer.resetAllSettings(self: SettingsServiceServer, player: Player)
	if not DataService:hasProfile(player) then
		return
	end

	local newSettings = {}
	for settingName, schema in SETTINGS_SCHEMA do
		newSettings[settingName] = schema.default
	end

	DataService:set(player, { "Settings" }, newSettings)

	self.OnSettingChanged:Fire(player, "*", newSettings, nil)
	self.Networker:fire({ player }, "SettingsLoaded", newSettings)
end

function SettingsServiceServer.UpdateSetting(
	self: SettingsServiceServer,
	player: Player,
	settingName: string,
	value: any
)
	self:updateSetting(player, settingName, value)
end

function SettingsServiceServer.GetSettings(self: SettingsServiceServer, player: Player)
	DataService:waitForData(player)
	local settings = self:getSettings(player)
	self.Networker:fire({ player }, "SettingsLoaded", settings)
end

function SettingsServiceServer.ResetSettings(self: SettingsServiceServer, player: Player)
	self:resetAllSettings(player)
end

-- Tutorial completion methods
function SettingsServiceServer.GetTutorialStatus(self: SettingsServiceServer, player: Player)
	DataService:waitForData(player)
	local completed = DataService:get(player, { "TutorialCompleted" }) or false
	self.Networker:fire({ player }, "TutorialStatus", completed)
end

function SettingsServiceServer.CompleteTutorial(self: SettingsServiceServer, player: Player)
	if not DataService:hasProfile(player) then
		return
	end
	DataService:set(player, { "TutorialCompleted" }, true)
	self.Networker:fire({ player }, "TutorialStatus", true)

	-- Track tutorial completion
	if AnalyticsService then
		AnalyticsService:trackTutorialCompleted(player)
	end
end

function SettingsServiceServer.SkipTutorial(self: SettingsServiceServer, player: Player, atStep: number?)
	if not DataService:hasProfile(player) then
		return
	end
	DataService:set(player, { "TutorialCompleted" }, true)
	self.Networker:fire({ player }, "TutorialStatus", true)

	-- Track tutorial skip with step info
	if AnalyticsService then
		AnalyticsService:trackTutorialSkipped(player, atStep)
	end
end

function SettingsServiceServer.ResetTutorial(self: SettingsServiceServer, player: Player)
	if not DataService:hasProfile(player) then
		return
	end
	DataService:set(player, { "TutorialCompleted" }, false)
	self.Networker:fire({ player }, "TutorialStatus", false)
end

SettingsServiceServer.SETTINGS_SCHEMA = SETTINGS_SCHEMA

return SettingsServiceServer
