-- Data Template for player data
-- This defines the structure of all player data that will be saved

return {
	-- Currency
	Coins = 0,

	-- Tile Cosmetics
	OwnedTileColors = { ["tan"] = true, ["coal"] = true, ["snow"] = true }, -- Initial basic colors
	EquippedColors = {
		Tile = "tan",
		Text = "coal",
		Stroke = "tan",
	},

	-- Styles System (1 slot free, slots 2-3 cost robux)
	-- Each spin replaces the style in the chosen slot - no collection of owned styles
	EquippedAbilities = { [1] = "basic" }, -- { [slotIndex] = styleId } - Basic equipped in slot 1
	UnlockedAbilitySlots = 1, -- Default 1 free slot, max 3 (slots 2-3 cost robux)
	ActiveAbilitySlot = 1, -- Which slot is currently selected for use in games

	-- Guns (purchased with cash)
	OwnedGuns = { pistol = true }, -- { [gunId] = true } - Pistol is default
	EquippedGun = "pistol", -- gunId or empty string - Pistol equipped by default

	-- Gun Skins (purchased with cash)
	OwnedSkins = {}, -- { [skinId] = true }
	EquippedSkin = "", -- skinId or empty string (single skin equipped globally)

	-- Codes System
	RedeemedCodes = {}, -- { [codeString] = true }

	-- Statistics
	Stats = {
		Wins = 0,
		Losses = 0,
		GamesPlayed = 0,
		TotalKills = 0,
		QuestionsAnswered = 0,
		CorrectAnswers = 0,
		CoinsEarned = 0,
		TotalPoints = 0, -- Lifetime Scrabble points
		TotalWords = 0, -- Lifetime words placed
		CurrentWinStreak = 0, -- Current consecutive wins
		HighestStreak = 0, -- Best win streak ever
		TimePlayed = 0, -- seconds
	},

	-- Settings
	Settings = {
		LobbyMusicVolume = 0.5,
		GameMusicVolume = 0.5,
		SFXVolume = 0.5,
	},

	-- Tasks progress
	DailyTasks = {},
	WeeklyTasks = {},
	LastDailyReset = 0,
	LastWeeklyReset = 0,

	-- Daily Rewards
	DailyRewardStreak = 0, -- Current consecutive days claimed
	LastDailyRewardClaim = 0, -- Timestamp of last claim

	-- Gamepasses (cached for fast lookup)
	Gamepasses = {}, -- { [gamepassId] = true }

	-- Metadata
	FirstJoin = 0,
	LastJoin = 0,
}
