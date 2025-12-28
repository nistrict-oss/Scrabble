--[[
	Colors.luau
	
	Central palette for tile customization.
]]

local Colors = {
	Palette = {
		-- ============ COMMON (Free defaults) ============
		tan = {
			Id = "tan",
			Name = "Classic Tan",
			Value = Color3.fromRGB(245, 225, 180),
			Rarity = "Common",
			Price = 0,
		},
		coal = {
			Id = "coal",
			Name = "Charcoal",
			Value = Color3.fromRGB(40, 40, 40),
			Rarity = "Common",
			Price = 0,
		},
		snow = {
			Id = "snow",
			Name = "Pure Snow",
			Value = Color3.fromRGB(255, 255, 255),
			Rarity = "Common",
			Price = 0,
		},

		-- ============ RARE (500 coins) ============
		crimson = {
			Id = "crimson",
			Name = "Crimson Red",
			Value = Color3.fromRGB(180, 20, 20),
			Rarity = "Rare",
			Price = 500,
		},
		ocean = {
			Id = "ocean",
			Name = "Ocean Blue",
			Value = Color3.fromRGB(20, 80, 180),
			Rarity = "Rare",
			Price = 500,
		},
		forest = {
			Id = "forest",
			Name = "Forest Green",
			Value = Color3.fromRGB(20, 100, 40),
			Rarity = "Rare",
			Price = 500,
		},
		sunset = {
			Id = "sunset",
			Name = "Sunset Orange",
			Value = Color3.fromRGB(255, 120, 50),
			Rarity = "Rare",
			Price = 500,
		},
		lemon = {
			Id = "lemon",
			Name = "Lemon Yellow",
			Value = Color3.fromRGB(255, 230, 50),
			Rarity = "Rare",
			Price = 500,
		},
		sky = {
			Id = "sky",
			Name = "Sky Blue",
			Value = Color3.fromRGB(135, 200, 250),
			Rarity = "Rare",
			Price = 500,
		},
		bubblegum = {
			Id = "bubblegum",
			Name = "Bubblegum Pink",
			Value = Color3.fromRGB(255, 150, 180),
			Rarity = "Rare",
			Price = 500,
		},
		lavender = {
			Id = "lavender",
			Name = "Lavender",
			Value = Color3.fromRGB(200, 170, 230),
			Rarity = "Rare",
			Price = 500,
		},
		peach = {
			Id = "peach",
			Name = "Peach Blush",
			Value = Color3.fromRGB(255, 200, 180),
			Rarity = "Rare",
			Price = 500,
		},
		navy = {
			Id = "navy",
			Name = "Navy Blue",
			Value = Color3.fromRGB(20, 30, 80),
			Rarity = "Rare",
			Price = 500,
		},
		gunmetal = {
			Id = "gunmetal",
			Name = "Gunmetal",
			Value = Color3.fromRGB(70, 75, 85),
			Rarity = "Rare",
			Price = 500,
		},
		olive = {
			Id = "olive",
			Name = "Olive Drab",
			Value = Color3.fromRGB(85, 90, 45),
			Rarity = "Rare",
			Price = 500,
		},
		maroon = {
			Id = "maroon",
			Name = "Maroon",
			Value = Color3.fromRGB(80, 20, 30),
			Rarity = "Rare",
			Price = 500,
		},

		-- ============ EPIC (1500 coins) ============
		royal = {
			Id = "royal",
			Name = "Royal Purple",
			Value = Color3.fromRGB(100, 40, 180),
			Rarity = "Epic",
			Price = 1500,
		},
		teal = {
			Id = "teal",
			Name = "Electric Teal",
			Value = Color3.fromRGB(0, 180, 180),
			Rarity = "Epic",
			Price = 1500,
		},
		rose = {
			Id = "rose",
			Name = "Rose Gold",
			Value = Color3.fromRGB(220, 160, 150),
			Rarity = "Epic",
			Price = 1500,
		},
		mint = {
			Id = "mint",
			Name = "Fresh Mint",
			Value = Color3.fromRGB(150, 230, 200),
			Rarity = "Epic",
			Price = 1500,
		},
		hotpink = {
			Id = "hotpink",
			Name = "Hot Pink",
			Value = Color3.fromRGB(255, 50, 150),
			Rarity = "Epic",
			Price = 1500,
		},
		aqua = {
			Id = "aqua",
			Name = "Aquamarine",
			Value = Color3.fromRGB(100, 220, 220),
			Rarity = "Epic",
			Price = 1500,
		},
		wine = {
			Id = "wine",
			Name = "Burgundy Wine",
			Value = Color3.fromRGB(100, 20, 40),
			Rarity = "Epic",
			Price = 1500,
		},
		magenta = {
			Id = "magenta",
			Name = "Electric Magenta",
			Value = Color3.fromRGB(255, 0, 144),
			Rarity = "Epic",
			Price = 1500,
		},
		bronze = {
			Id = "bronze",
			Name = "Aged Bronze",
			Value = Color3.fromRGB(160, 120, 70),
			Rarity = "Epic",
			Price = 1500,
		},
		indigo = {
			Id = "indigo",
			Name = "Deep Indigo",
			Value = Color3.fromRGB(60, 40, 130),
			Rarity = "Epic",
			Price = 1500,
		},

		-- ============ LEGENDARY - Solid (5000 coins) ============
		-- All legendaries have special textures for premium look
		gold = {
			Id = "gold",
			Name = "Solid Gold",
			Value = Color3.fromRGB(255, 215, 0),
			Rarity = "Legendary",
			Price = 5000,
			Texture = "metallic", -- Shiny metallic shimmer
		},
		platinum = {
			Id = "platinum",
			Name = "Platinum",
			Value = Color3.fromRGB(220, 225, 235),
			Rarity = "Legendary",
			Price = 5000,
			Texture = "brushed", -- Brushed metal effect
		},
		emerald = {
			Id = "emerald",
			Name = "Emerald",
			Value = Color3.fromRGB(0, 180, 80),
			Rarity = "Legendary",
			Price = 5000,
			Texture = "gem", -- Crystal/gem facets
		},
		sapphire = {
			Id = "sapphire",
			Name = "Sapphire",
			Value = Color3.fromRGB(30, 80, 200),
			Rarity = "Legendary",
			Price = 5000,
			Texture = "gem",
		},
		ruby = {
			Id = "ruby",
			Name = "Ruby",
			Value = Color3.fromRGB(200, 20, 60),
			Rarity = "Legendary",
			Price = 5000,
			Texture = "gem",
		},
		obsidian = {
			Id = "obsidian",
			Name = "Obsidian",
			Value = Color3.fromRGB(20, 15, 25),
			Rarity = "Legendary",
			Price = 5000,
			Texture = "glass", -- Volcanic glass effect
		},
		amethyst = {
			Id = "amethyst",
			Name = "Amethyst",
			Value = Color3.fromRGB(155, 90, 200),
			Rarity = "Legendary",
			Price = 5000,
			Texture = "gem",
		},
		titanium = {
			Id = "titanium",
			Name = "Titanium",
			Value = Color3.fromRGB(135, 140, 155),
			Rarity = "Legendary",
			Price = 5000,
			Texture = "brushed",
		},
		princess = {
			Id = "princess",
			Name = "Princess Pink",
			Value = Color3.fromRGB(255, 130, 190),
			Rarity = "Legendary",
			Price = 5000,
			Texture = "sparkle", -- Glitter/sparkle effect
		},

		-- ============ LEGENDARY - Animated (10000 coins) ============
		-- These have IsAnimated = true flag for cycling colors
		chroma = {
			Id = "chroma",
			Name = "Prismatic Chroma",
			Value = Color3.fromRGB(255, 255, 255),
			Rarity = "Legendary",
			Price = 10000,
			IsAnimated = true,
			AnimationType = "rainbow",
		},
		aurora = {
			Id = "aurora",
			Name = "Aurora Borealis",
			Value = Color3.fromRGB(100, 255, 200),
			Rarity = "Legendary",
			Price = 10000,
			IsAnimated = true,
			AnimationType = "aurora",
		},
		lava = {
			Id = "lava",
			Name = "Molten Lava",
			Value = Color3.fromRGB(255, 100, 0),
			Rarity = "Legendary",
			Price = 10000,
			IsAnimated = true,
			AnimationType = "lava",
		},
		galaxy = {
			Id = "galaxy",
			Name = "Galaxy Swirl",
			Value = Color3.fromRGB(100, 50, 180),
			Rarity = "Legendary",
			Price = 10000,
			IsAnimated = true,
			AnimationType = "galaxy",
		},
		cotton = {
			Id = "cotton",
			Name = "Cotton Candy",
			Value = Color3.fromRGB(255, 180, 220),
			Rarity = "Legendary",
			Price = 10000,
			IsAnimated = true,
			AnimationType = "candy",
		},
		toxic = {
			Id = "toxic",
			Name = "Toxic Waste",
			Value = Color3.fromRGB(100, 255, 0),
			Rarity = "Legendary",
			Price = 10000,
			IsAnimated = true,
			AnimationType = "toxic",
		},
		oceanwave = {
			Id = "oceanwave",
			Name = "Ocean Wave",
			Value = Color3.fromRGB(30, 130, 200),
			Rarity = "Legendary",
			Price = 10000,
			IsAnimated = true,
			AnimationType = "ocean",
		},
		sunsetdream = {
			Id = "sunsetdream",
			Name = "Sunset Dream",
			Value = Color3.fromRGB(255, 120, 180),
			Rarity = "Legendary",
			Price = 10000,
			IsAnimated = true,
			AnimationType = "sunset",
		},
		neonpulse = {
			Id = "neonpulse",
			Name = "Neon Pulse",
			Value = Color3.fromRGB(0, 255, 200),
			Rarity = "Legendary",
			Price = 10000,
			IsAnimated = true,
			AnimationType = "neon",
		},
	},

	DEFAULT_COLORS = {
		Tile = "tan",
		Text = "coal",
		Stroke = "tan",
	},
}

function Colors.getColor(id: string)
	return Colors.Palette[id] or Colors.Palette.tan
end

function Colors.getPalette()
	return Colors.Palette
end

return Colors
