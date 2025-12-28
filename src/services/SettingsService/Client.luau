local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)

local SettingsServiceClient = {
	Networker = nil,
	Settings = {
		LobbyMusicVolume = 0.5,
		GameMusicVolume = 0.3,
		SFXVolume = 0.8,
		ShowStreaks = true,
		ShowTilePoints = true,
		ConfirmMoves = false,
	},

	-- Tutorial state
	TutorialCompleted = false,

	OnSettingsLoaded = Signal.new(),
	OnSettingUpdated = Signal.new(),
	OnTutorialStatusChanged = Signal.new(),
}

export type SettingsServiceClient = typeof(SettingsServiceClient) & {
	Networker: Networker.Client,
}

function SettingsServiceClient.init(self: SettingsServiceClient)
	self.Networker = Networker.client.new("SettingsService", self)

	task.defer(function()
		self.Networker:fire("GetSettings")
		self.Networker:fire("GetTutorialStatus")
	end)
end

function SettingsServiceClient.applySettings(self: SettingsServiceClient)
	local musicGroup = SoundService:FindFirstChild("Music")
	if musicGroup then
		musicGroup.Volume = 1 -- Volume now controlled per-sound or by group if it was master
	end

	local sfxGroup = SoundService:FindFirstChild("SFX")
	if sfxGroup then
		sfxGroup.Volume = self.Settings.SFXVolume or 0.8
	end
end

function SettingsServiceClient.SettingsLoaded(self: SettingsServiceClient, settings: any)
	if settings then
		for key, value in settings do
			self.Settings[key] = value
		end
	end
	self:applySettings()
	self.OnSettingsLoaded:Fire(self.Settings)
end

function SettingsServiceClient.SettingUpdated(self: SettingsServiceClient, settingName: string, value: any)
	self.Settings[settingName] = value
	self:applySettings()
	self.OnSettingUpdated:Fire(settingName, value)
end

function SettingsServiceClient.getSettings(self: SettingsServiceClient): any
	return table.clone(self.Settings)
end

function SettingsServiceClient.getSetting(self: SettingsServiceClient, settingName: string): any?
	return self.Settings[settingName]
end

function SettingsServiceClient.updateSetting(self: SettingsServiceClient, settingName: string, value: any)
	self.Settings[settingName] = value
	self:applySettings()

	self.Networker:fire("UpdateSetting", settingName, value)

	self.OnSettingUpdated:Fire(settingName, value)
end

function SettingsServiceClient.resetSettings(self: SettingsServiceClient)
	self.Networker:fire("ResetSettings")
end

function SettingsServiceClient.showStreaks(self: SettingsServiceClient): boolean
	return self.Settings.ShowStreaks ~= false
end

function SettingsServiceClient.showTableInfo(self: SettingsServiceClient): boolean
	return self.Settings.ShowTableInfo ~= false
end

function SettingsServiceClient.showKeypad(self: SettingsServiceClient): boolean
	return self.Settings.ShowKeypad ~= false
end

function SettingsServiceClient.isScreenShakeEnabled(self: SettingsServiceClient): boolean
	return self.Settings.ScreenShakeEnabled ~= false
end

function SettingsServiceClient.getKeybinds(self: SettingsServiceClient): { [string]: string }
	return {
		Add = self.Settings.KeyAdd or "A",
		Subtract = self.Settings.KeySubtract or "S",
		Multiply = self.Settings.KeyMultiply or "M",
		Divide = self.Settings.KeyDivide or "D",
	}
end

-- Convert key name string to Enum.KeyCode
function SettingsServiceClient.keyNameToKeyCode(keyName: string): Enum.KeyCode?
	local success, keyCode = pcall(function()
		return Enum.KeyCode[keyName]
	end)
	if success and keyCode then
		return keyCode
	end
	return nil
end

-- Tutorial methods
function SettingsServiceClient.TutorialStatus(self: SettingsServiceClient, completed: boolean)
	self.TutorialCompleted = completed
	self.OnTutorialStatusChanged:Fire(completed)
end

function SettingsServiceClient.isTutorialCompleted(self: SettingsServiceClient): boolean
	return self.TutorialCompleted
end

function SettingsServiceClient.completeTutorial(self: SettingsServiceClient)
	self.TutorialCompleted = true
	self.Networker:fire("CompleteTutorial")
	self.OnTutorialStatusChanged:Fire(true)
end

function SettingsServiceClient.skipTutorial(self: SettingsServiceClient, atStep: number?)
	self.TutorialCompleted = true
	self.Networker:fire("SkipTutorial", atStep or 1)
	self.OnTutorialStatusChanged:Fire(true)
end

function SettingsServiceClient.resetTutorial(self: SettingsServiceClient)
	self.TutorialCompleted = false
	self.Networker:fire("ResetTutorial")
	self.OnTutorialStatusChanged:Fire(false)
end

return SettingsServiceClient
