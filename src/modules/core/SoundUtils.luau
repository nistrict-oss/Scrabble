-- Sound utility for playing UI sounds with settings support
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local GameConstants = require(script.Parent.GameConstants)

-- Try to get SettingsServiceClient (may not exist in Hoarcekat)
local SettingsServiceClient
pcall(function()
	SettingsServiceClient = require(ReplicatedStorage.Shared.Services.SettingsService.SettingsServiceClient)
end)

local SoundUtils = {}

-- Check if we should play sounds (prevents Hoarcekat from spamming sounds)
function SoundUtils.canPlaySounds(): boolean
	-- Don't play sounds if the game isn't running (e.g., Hoarcekat preview)
	return RunService:IsRunning()
end

-- Lobby music
local LOBBY_MUSIC_ID = "rbxassetid://114213622974713"
local MUSIC_FADE_TIME = 0.5 -- Fast, smooth fade duration
local lobbyMusic: Sound? = nil
local currentFadeTween: Tween? = nil

-- Loading screen sounds
local BUBBLE_POP_ID = "rbxassetid://85730811347567"
local UNDERWATER_AMBIENCE_ID = "rbxassetid://5033884807"

-- Check if SFX is enabled and get volume multiplier
function SoundUtils.getSFXVolume(): number
	if SettingsServiceClient then
		if not SettingsServiceClient:isSFXEnabled() then
			return 0
		end
		return SettingsServiceClient.Settings.SFXVolume or 0.8
	end
	return 0.8 -- Default if settings not available
end

-- Check if Music is enabled and get volume multiplier
function SoundUtils.getMusicVolume(): number
	if SettingsServiceClient then
		if not SettingsServiceClient:isMusicEnabled() then
			return 0
		end
		return SettingsServiceClient.Settings.MusicVolume or 0.7
	end
	return 0.7 -- Default if settings not available
end

-- Play lobby music (loops, respects settings, fades in smoothly)
function SoundUtils.playLobbyMusic()
	-- Don't play sounds in Hoarcekat or when not running
	if not SoundUtils.canPlaySounds() then return end
	
	-- Cancel any existing fade
	if currentFadeTween then
		currentFadeTween:Cancel()
		currentFadeTween = nil
	end
	
	-- Clean up any existing lobby music sounds first
	for _, child in SoundService:GetChildren() do
		if child:IsA("Sound") and child.Name == "LobbyMusic" and child ~= lobbyMusic then
			child:Destroy()
		end
	end
	
	-- If already playing, just fade back in
	if lobbyMusic and lobbyMusic.Parent then
		local targetVolume = 0.5
		local fadeTween = TweenService:Create(
			lobbyMusic,
			TweenInfo.new(MUSIC_FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Volume = targetVolume }
		)
		currentFadeTween = fadeTween
		fadeTween:Play()
		return
	end
	
	-- Create or find Music group in SoundService
	local musicGroup = SoundService:FindFirstChild("Music")
	if not musicGroup then
		musicGroup = Instance.new("SoundGroup")
		musicGroup.Name = "Music"
		musicGroup.Volume = SoundUtils.getMusicVolume()
		musicGroup.Parent = SoundService
	end
	
	local newMusic = Instance.new("Sound")
	newMusic.Name = "LobbyMusic"
	newMusic.SoundId = LOBBY_MUSIC_ID
	newMusic.Volume = 0 -- Start at 0 for fade in
	newMusic.Looped = true
	newMusic.SoundGroup = musicGroup
	newMusic.Parent = SoundService
	newMusic:Play()
	lobbyMusic = newMusic
	
	-- Fade in
	local targetVolume = 0.5
	local fadeTween = TweenService:Create(
		newMusic,
		TweenInfo.new(MUSIC_FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Volume = targetVolume }
	)
	currentFadeTween = fadeTween
	fadeTween:Play()
end

-- Stop lobby music (fades out smoothly, then destroys)
function SoundUtils.stopLobbyMusic()
	-- Cancel any existing fade
	if currentFadeTween then
		currentFadeTween:Cancel()
		currentFadeTween = nil
	end
	
	if not lobbyMusic then
		return
	end
	
	-- Capture reference and clear immediately to prevent duplicates
	local sound = lobbyMusic
	lobbyMusic = nil
	
	-- Fade out then destroy
	local fadeTween = TweenService:Create(
		sound,
		TweenInfo.new(MUSIC_FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Volume = 0 }
	)
	currentFadeTween = fadeTween
	fadeTween:Play()
	fadeTween.Completed:Once(function()
		sound:Stop()
		sound:Destroy()
	end)
end

-- Check if lobby music is playing
function SoundUtils.isLobbyMusicPlaying(): boolean
	return lobbyMusic ~= nil and lobbyMusic.IsPlaying
end

-- ============== LOADING SCREEN SOUNDS ==============

local underwaterAmbience: Sound? = nil
local ambienceFadeTween: Tween? = nil

-- Play underwater bubbling ambience (for loading screen only)
function SoundUtils.playUnderwaterAmbience()
	if not SoundUtils.canPlaySounds() then return nil end
	
	-- Cancel any existing fade
	if ambienceFadeTween then
		ambienceFadeTween:Cancel()
		ambienceFadeTween = nil
	end
	
	-- Clean up any existing ambience
	for _, child in SoundService:GetChildren() do
		if child:IsA("Sound") and child.Name == "UnderwaterAmbience" and child ~= underwaterAmbience then
			child:Destroy()
		end
	end
	
	-- If already playing, just fade back in
	if underwaterAmbience and underwaterAmbience.Parent then
		local fadeTween = TweenService:Create(
			underwaterAmbience,
			TweenInfo.new(MUSIC_FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Volume = 0.4 }
		)
		ambienceFadeTween = fadeTween
		fadeTween:Play()
		return underwaterAmbience
	end
	
	-- Create or find Music group
	local musicGroup = SoundService:FindFirstChild("Music")
	if not musicGroup then
		musicGroup = Instance.new("SoundGroup")
		musicGroup.Name = "Music"
		musicGroup.Volume = SoundUtils.getMusicVolume()
		musicGroup.Parent = SoundService
	end
	
	local newAmbience = Instance.new("Sound")
	newAmbience.Name = "UnderwaterAmbience"
	newAmbience.SoundId = UNDERWATER_AMBIENCE_ID
	newAmbience.Volume = 0
	newAmbience.Looped = true
	newAmbience.SoundGroup = musicGroup
	newAmbience.Parent = SoundService
	newAmbience:Play()
	underwaterAmbience = newAmbience
	
	-- Fade in
	local fadeTween = TweenService:Create(
		newAmbience,
		TweenInfo.new(MUSIC_FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Volume = 0.4 }
	)
	ambienceFadeTween = fadeTween
	fadeTween:Play()
	
	return newAmbience
end

-- Stop underwater ambience (fades out)
function SoundUtils.stopUnderwaterAmbience()
	if ambienceFadeTween then
		ambienceFadeTween:Cancel()
		ambienceFadeTween = nil
	end
	
	if not underwaterAmbience then return end
	
	local sound = underwaterAmbience
	underwaterAmbience = nil
	
	local fadeTween = TweenService:Create(
		sound,
		TweenInfo.new(MUSIC_FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Volume = 0 }
	)
	ambienceFadeTween = fadeTween
	fadeTween:Play()
	fadeTween.Completed:Once(function()
		sound:Stop()
		sound:Destroy()
	end)
end

-- Play bubble pop sound (for loading screen letter reveal)
function SoundUtils.playBubblePop()
	if not SoundUtils.canPlaySounds() then return nil end
	
	local sfxVolume = SoundUtils.getSFXVolume()
	if sfxVolume <= 0 then return nil end
	
	local sound = Instance.new("Sound")
	sound.SoundId = BUBBLE_POP_ID
	sound.Volume = 0.3 * sfxVolume
	sound.PlaybackSpeed = 0.9 + math.random() * 0.2 -- Slight pitch variation
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	
	return sound
end

-- Play a sound with settings-aware volume
function SoundUtils.playSound(soundId: string, baseVolume: number?)
	-- Don't play sounds in Hoarcekat or when not running
	if not SoundUtils.canPlaySounds() then return nil end
	
	local sfxVolume = SoundUtils.getSFXVolume()
	if sfxVolume <= 0 then return nil end
	
	local volume = (baseVolume or 0.5) * sfxVolume
	
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	
	return sound
end

-- Play a sound from GameConstants.SOUNDS with matching volume from VOLUMES
function SoundUtils.playSoundFromConstants(soundName: string)
	local soundId = GameConstants.Sounds[soundName]
	local baseVolume = GameConstants.Volumes[soundName] or 0.5
	
	if soundId then
		return SoundUtils.playSound(soundId, baseVolume)
	end
	return nil
end

-- Shorthand functions for common sounds
function SoundUtils.playButtonClick()
	return SoundUtils.playSoundFromConstants("BUTTON_CLICK")
end

function SoundUtils.playButtonHover()
	return SoundUtils.playSoundFromConstants("BUTTON_HOVER")
end

function SoundUtils.playTyping()
	return SoundUtils.playSoundFromConstants("TYPING")
end

function SoundUtils.playTimerTick()
	return SoundUtils.playSoundFromConstants("TIMER_TICK")
end

function SoundUtils.playSpinWin()
	return SoundUtils.playSoundFromConstants("SPIN_WIN")
end

function SoundUtils.playSpinWinRare()
	return SoundUtils.playSoundFromConstants("SPIN_WIN_RARE")
end

function SoundUtils.playPurchaseSuccess()
	return SoundUtils.playSoundFromConstants("PURCHASE_SUCCESS")
end

-- Ability activation sound
local ABILITY_ACTIVATE_ID = "rbxassetid://119695407202262"
function SoundUtils.playAbilityActivate()
	return SoundUtils.playSound(ABILITY_ACTIVATE_ID, 0.8)
end

return SoundUtils

