-- Sound utility for playing UI sounds with settings support
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local GameConstants = require(script.Parent.GameConstants)

local SoundUtils = {}

-- Menu/Lobby music (same as loading screen music for seamless transition)
local LOBBY_MUSIC_ID = "rbxassetid://83775010804048"
local MUSIC_FADE_TIME = 0.5 -- Fast, smooth fade duration
local lobbyMusic: Sound? = nil
local gameMusic: Sound? = nil
local loadingMusic: Sound? = nil
local currentFadeTween: Tween? = nil

-- Loading screen sounds
local BUBBLE_POP_ID = "rbxassetid://85730811347567"

-- Try to get SettingsServiceClient (may not exist in Hoarcekat)
local SettingsServiceClient
pcall(function()
	SettingsServiceClient = require(ReplicatedStorage.Shared.Services.SettingsService.SettingsServiceClient)
end)

-- Preloaded sound cache for instant playback
local preloadedSounds: { [string]: Sound } = {}
local isPreloaded = false

-- Preload all game sounds for instant playback
function SoundUtils.preloadSounds()
	if isPreloaded then
		return
	end

	local ContentProvider = game:GetService("ContentProvider")
	local soundsToPreload = {}

	-- Collect all sound IDs from GameConstants
	for _, soundId in pairs(GameConstants.SOUNDS) do
		table.insert(soundsToPreload, soundId)
	end

	-- Preload using ContentProvider
	local success, err = pcall(function()
		ContentProvider:PreloadAsync(soundsToPreload)
	end)

	if success then
		print("✓ Preloaded", #soundsToPreload, "game sounds")
		isPreloaded = true
	else
		warn("Failed to preload sounds:", err)
	end
end

-- Check if we should play sounds (prevents Hoarcekat from spamming sounds)
function SoundUtils.canPlaySounds(): boolean
	-- Don't play sounds if the game isn't running (e.g., Hoarcekat preview)
	return RunService:IsRunning()
end

-- Check if SFX volume multiplier
function SoundUtils.getSFXVolume(): number
	if SettingsServiceClient then
		return SettingsServiceClient.Settings.SFXVolume or 0.8
	end
	return 0.8 -- Default if settings not available
end

-- Check if Music volume multiplier
function SoundUtils.getMusicVolume(musicType: ("Lobby" | "Game")?): number
	if SettingsServiceClient then
		if musicType == "Lobby" then
			return SettingsServiceClient.Settings.LobbyMusicVolume or 0.5
		elseif musicType == "Game" then
			return SettingsServiceClient.Settings.GameMusicVolume or 0.3
		end

		return SettingsServiceClient.Settings.MusicVolume or 0.7
	end
	return 0.7 -- Default if settings not available
end

-- Play lobby music (loops, respects settings, fades in smoothly)
function SoundUtils.playLobbyMusic()
	-- Don't play sounds in Hoarcekat or when not running
	if not SoundUtils.canPlaySounds() then
		return
	end

	-- If loading music is playing, don't play lobby music
	if SoundUtils.isLoadingMusicPlaying() then
		return
	end

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
		local targetVolume = SoundUtils.getMusicVolume("Lobby")
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
		musicGroup.Parent = SoundService
	end
	musicGroup.Volume = 1

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
	local targetVolume = SoundUtils.getMusicVolume("Lobby")
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

-- Check if loading music is playing
function SoundUtils.isLoadingMusicPlaying(): boolean
	return loadingMusic ~= nil and loadingMusic.IsPlaying
end

-- ============== LOADING MUSIC (Deprecated) ==============
-- Loading music functionality has been merged into Lobby Music.
-- playLobbyMusic() is now called directly from LoadingScreen.

-- ============== GAME MUSIC PLAYLIST ==============

local GAME_MUSIC_IDS = {
	"rbxassetid://9045765634",
	"rbxassetid://9045766377",
	"rbxassetid://9045766074",
	"rbxassetid://1842150151",
	"rbxassetid://9045765295",
	"rbxassetid://9045764969",
	"rbxassetid://1842150565",
	"rbxassetid://1848056295",
	"rbxassetid://1842150470",
	"rbxassetid://85297174440725",
}

local gameMusicConn: RBXScriptConnection? = nil

-- Play a random game music track
function SoundUtils.playGameMusic()
	if not SoundUtils.canPlaySounds() then
		return
	end

	-- If already playing, don't restart
	if gameMusic and gameMusic.IsPlaying then
		return
	end

	local function playNextRandom()
		-- Clean up old connection
		if gameMusicConn then
			gameMusicConn:Disconnect()
			gameMusicConn = nil
		end

		-- Destroy old sound
		if gameMusic then
			gameMusic:Destroy()
			gameMusic = nil
		end

		-- Pick a random track
		local randomId = GAME_MUSIC_IDS[math.random(#GAME_MUSIC_IDS)]

		local musicGroup = SoundService:FindFirstChild("Music")
		if not musicGroup then
			musicGroup = Instance.new("SoundGroup")
			musicGroup.Name = "Music"
			musicGroup.Volume = 1
			musicGroup.Parent = SoundService
		end

		local newSound = Instance.new("Sound")
		newSound.Name = "GameMusic"
		newSound.SoundId = randomId
		newSound.Volume = 0 -- Fade in
		newSound.SoundGroup = musicGroup
		newSound.Parent = SoundService
		newSound:Play()

		gameMusic = newSound

		-- Loop by picking another random when finished
		gameMusicConn = newSound.Ended:Connect(function()
			playNextRandom()
		end)

		-- Fade in
		local targetVolume = SoundUtils.getMusicVolume("Game")
		local fadeTween = TweenService:Create(
			newSound,
			TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Volume = targetVolume }
		)
		fadeTween:Play()
	end

	playNextRandom()
end

-- Stop game music with fade out
function SoundUtils.stopGameMusic()
	if gameMusicConn then
		gameMusicConn:Disconnect()
		gameMusicConn = nil
	end

	if not gameMusic then
		return
	end

	local sound = gameMusic
	gameMusic = nil

	local fadeOut = TweenService:Create(
		sound,
		TweenInfo.new(MUSIC_FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Volume = 0 }
	)
	fadeOut:Play()
	fadeOut.Completed:Once(function()
		sound:Stop()
		sound:Destroy()
	end)
end


-- Play bubble pop sound (for loading screen letter reveal)
function SoundUtils.playBubblePop()
	if not SoundUtils.canPlaySounds() then
		return nil
	end

	local sfxVolume = SoundUtils.getSFXVolume()
	if sfxVolume <= 0 then
		return nil
	end

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
	if not SoundUtils.canPlaySounds() then
		return nil
	end

	local sfxVolume = SoundUtils.getSFXVolume()
	if sfxVolume <= 0 then
		return nil
	end

	local sfxGroup = SoundService:FindFirstChild("SFX")
	if not sfxGroup then
		sfxGroup = Instance.new("SoundGroup")
		sfxGroup.Name = "SFX"
		sfxGroup.Parent = SoundService
	end
	sfxGroup.Volume = sfxVolume

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = (baseVolume or 0.5) -- Volume is already controlled by Group
	sound.SoundGroup = sfxGroup
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)

	return sound
end

-- Play a sound from GameConstants.SOUNDS with matching volume from VOLUMES
function SoundUtils.playSoundFromConstants(soundName: string)
	local soundId = GameConstants.SOUNDS[soundName]
	local baseVolume = GameConstants.VOLUMES[soundName] or 0.5

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

function SoundUtils.playWoosh()
	return
end

function SoundUtils.playVictory()
	return SoundUtils.playSoundFromConstants("VICTORY")
end

function SoundUtils.playDefeat()
	return SoundUtils.playSoundFromConstants("DEFEAT")
end

function SoundUtils.playCorrect()
	return SoundUtils.playSoundFromConstants("CORRECT_ANSWER")
end

function SoundUtils.playWrong()
	return SoundUtils.playSoundFromConstants("WRONG_ANSWER")
end

function SoundUtils.playTilePop()
	return SoundUtils.playSoundFromConstants("TILE_POP")
end

function SoundUtils.playChatNotification()
	return SoundUtils.playSoundFromConstants("CHAT_NOTIFICATION")
end

function SoundUtils.playScoreCollect()
	if not SoundUtils.canPlaySounds() then
		return nil
	end

	local sfxVolume = SoundUtils.getSFXVolume()
	if sfxVolume <= 0 then
		return nil
	end

	local soundId = GameConstants.SOUNDS.SCORE_COLLECT
	local baseVolume = (GameConstants.VOLUMES.SCORE_COLLECT or 1.0) * sfxVolume

	-- Create sound with slight variations to prevent Roblox from skipping instances
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = baseVolume
	-- Add slight random pitch variation (0.98 to 1.02) to ensure each instance is unique
	sound.PlaybackSpeed = 0.98 + math.random() * 0.04
	sound.Parent = SoundService

	-- Add tiny random delay (0-50ms) to prevent simultaneous creation issues
	local delay = math.random() * 0.05
	task.delay(delay, function()
		if sound.Parent then
			sound:Play()
		end
	end)

	sound.Ended:Once(function()
		sound:Destroy()
	end)

	return sound
end

-- Ability activation sound
local ABILITY_ACTIVATE_ID = "rbxassetid://119695407202262"
function SoundUtils.playAbilityActivate()
	return SoundUtils.playSound(ABILITY_ACTIVATE_ID, 0.8)
end

-- Connect settings listeners
if SettingsServiceClient then
	SettingsServiceClient.OnSettingUpdated:Connect(function(name, _)
		if name == "LobbyMusicVolume" then
			if lobbyMusic and lobbyMusic.Parent then
				lobbyMusic.Volume = SoundUtils.getMusicVolume("Lobby")
			end
		elseif name == "GameMusicVolume" then
			if gameMusic and gameMusic.Parent then
				gameMusic.Volume = SoundUtils.getMusicVolume("Game")
			end
		elseif name == "SFXVolume" then
			local sfxGroup = SoundService:FindFirstChild("SFX")
			if sfxGroup then
				sfxGroup.Volume = SoundUtils.getSFXVolume()
			end
		end
	end)
end

return SoundUtils
