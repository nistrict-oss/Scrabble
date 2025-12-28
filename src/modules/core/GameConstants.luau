local GameConstants = {}

GameConstants.Images = {
	Navigator = {
		Customization = {
			ImageSelected = "rbxassetid://127186202712390",
			ImageUnselected = "rbxassetid://77508984950500",
			LayoutOrder = 2,
		},
		Leaderboards = {
			ImageSelected = "rbxassetid://96052339210237",
			ImageUnselected = "rbxassetid://88477302958496",
			LayoutOrder = 4,
		},
		Servers = {
			ImageSelected = "rbxassetid://125569767011561",
			ImageUnselected = "rbxassetid://134714862487905",
			LayoutOrder = 1,
		},
		Settings = {
			ImageSelected = "rbxassetid://98033026835588",
			ImageUnselected = "rbxassetid://116515403472692",
			LayoutOrder = 5,
		},
		Shop = {
			ImageSelected = "rbxassetid://105172745487867",
			ImageUnselected = "rbxassetid://79624293413130",
			LayoutOrder = 3,
		},
	},
}

GameConstants.Colors = {
	White = Color3.fromRGB(255, 255, 255),
	Black = Color3.fromRGB(0, 0, 0),
	Gray = Color3.fromRGB(128, 128, 128),
	Red = Color3.fromRGB(255, 0, 0),
	Green = Color3.fromRGB(0, 255, 0),
	Blue = Color3.fromRGB(0, 0, 255),
	Yellow = Color3.fromRGB(255, 255, 0),
	Purple = Color3.fromRGB(128, 0, 128),
	Orange = Color3.fromRGB(255, 165, 0),
}

GameConstants.Gradients = {
	-- Pink gradient for active/selected buttons
	buttonInactive = {
		ColorSequenceKeypoint.new(0, Color3.fromRGB(254, 100, 192)),
		ColorSequenceKeypoint.new(0.918269, Color3.fromRGB(206, 96, 162)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(202, 96, 159)),
	},
	-- Blue gradient for inactive/unselected buttons
	buttonActive = {
		ColorSequenceKeypoint.new(0, Color3.fromRGB(68, 210, 253)),
		ColorSequenceKeypoint.new(0.89, Color3.fromRGB(62, 150, 227)),
		ColorSequenceKeypoint.new(0.91, Color3.fromRGB(50, 142, 240)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(63, 114, 233)),
	},
	-- Deep blue sleek gradient for frames and panels
	frame = {
		ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 45, 95)),
		ColorSequenceKeypoint.new(0.89, Color3.fromRGB(15, 30, 75)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 20, 60)),
	},
}

GameConstants.SOUNDS = {
	-- Input/Typing
	TYPING = "rbxassetid://11902740060",

	-- UI Interactions
	BUTTON_CLICK = "rbxassetid://5852470908",
	BUTTON_HOVER = "rbxassetid://6895079853",
	WOOSH = "rbxassetid://117297744119258", -- Woosh/swoosh for UI animations
	STREAK = "rbxassetid://7978512412", -- Streak milestone sound

	-- Gameplay feedback
	CORRECT_ANSWER = "rbxassetid://128170212983132", -- Correct answer chime
	WRONG_ANSWER = "rbxassetid://83517496538471", -- Wrong answer buzzer
	LIFE_LOST = "rbxassetid://9116795681", -- Losing a life
	VICTORY = "rbxassetid://1846266692", -- Winning the game
	DEFEAT = "rbxassetid://1846266716", -- Losing/eliminated

	-- Spin/Styles
	SPIN_WIN = "rbxassetid://17208361335",
	SPIN_WIN_RARE = "rbxassetid://8486683243", -- Epic/Legendary/Mathematic rarity

	-- Purchases
	PURCHASE_SUCCESS = "rbxassetid://10066947742",

	-- Tiles
	TILE_POP = "rbxassetid://6586979979",

	-- Chat
	CHAT_NOTIFICATION = "rbxassetid://18202483174",

	-- Score
	SCORE_COLLECT = "rbxassetid://97873131181477",
}

GameConstants.VOLUMES = {
	-- UI Interactions
	BUTTON_CLICK = 0.5,
	BUTTON_HOVER = 0.5,
	WOOSH = 0.6,
	STREAK = 0.7,

	-- Typing
	TYPING = 0.8,

	-- Gameplay feedback
	CORRECT_ANSWER = 0.7,
	WRONG_ANSWER = 0.6,
	LIFE_LOST = 0.7,
	VICTORY = 0.8,
	DEFEAT = 0.7,

	-- Spin/Styles
	SPIN_WIN = 0.7,
	SPIN_WIN_RARE = 0.8,

	-- Purchases
	PURCHASE_SUCCESS = 0.8,

	-- Tiles
	TILE_POP = 0.7,

	-- Chat
	CHAT_NOTIFICATION = 0.6,

	-- Score
	SCORE_COLLECT = 1,
}

return GameConstants
