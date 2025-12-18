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
	buttonActive = {
		ColorSequenceKeypoint.new(0, Color3.fromRGB(254, 100, 192)),
		ColorSequenceKeypoint.new(0.918269, Color3.fromRGB(206, 96, 162)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(202, 96, 159)),
	},
	-- Blue gradient for inactive/unselected buttons
	buttonInactive = {
		ColorSequenceKeypoint.new(0, Color3.fromRGB(68, 210, 253)),
		ColorSequenceKeypoint.new(0.89, Color3.fromRGB(62, 150, 227)),
		ColorSequenceKeypoint.new(0.91, Color3.fromRGB(50, 142, 240)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(63, 114, 233)),
	},
	-- Purple gradient for frames and panels
	frame = {
		ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 99, 174)),
		ColorSequenceKeypoint.new(0.89, Color3.fromRGB(90, 99, 174)),
		ColorSequenceKeypoint.new(0.91, Color3.fromRGB(81, 88, 156)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(81, 88, 156)),
	},
}

GameConstants.Sounds = {}

GameConstants.Volumes = {}

return GameConstants
