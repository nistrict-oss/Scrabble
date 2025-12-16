--[[
	Purchases.luau
	
	Centralized configuration for all gamepasses and products.
	Edit Roblox IDs here when publishing to production.
]]

local Purchases = {}

-- ============== GAMEPASSES ==============
-- Set the `robloxId` to your actual Roblox gamepass IDs in production

Purchases.GAMEPASSES = {
	Supporter = {
		robloxId = 1626449626,  -- Supporter Pass gamepass ID
		name = "Supporter",
		description = "2x Cash from all sources + [Supporter] chat tag!",
		price = 0,              -- Fetched from MarketplaceService
		icon = "💛",
	},
	ExtraLife = {
		robloxId = 1626215743,           -- Set to actual gamepass ID
		name = "Extra Life",
		description = "Start with 3 lives!",
		price = 0,
		icon = "❤️",
	},
	InstantSpin = {
		robloxId = 1616995420,           -- Set to actual gamepass ID
		name = "Instant Spin",
		description = "Skip spin animation!",
		price = 0,
		icon = "⚡",
	},
	LuckySpins = {
		robloxId = 1626497694,           -- Set to actual gamepass ID
		name = "Lucky Spins",
		description = "2x chance for Rare+ styles!",
		price = 0,
		icon = "🍀",
	},
}

-- Order for UI display
Purchases.GAMEPASS_ORDER = { "Supporter", "ExtraLife", "InstantSpin", "LuckySpins" }

-- ============== PRODUCTS ==============
-- Set the `robloxId` to your actual Roblox developer product IDs in production

Purchases.PRODUCTS = {
	Cash500 = {
		robloxId = 3477128757,           -- Set to actual product ID
		name = "500 Cash",
		description = "Starter bundle",
		price = 0,              -- Fetched from MarketplaceService
		icon = "💵",
		cash = 500,             -- Amount of cash to give
	},
	Cash1500 = {
		robloxId = 3477128895,           -- Set to actual product ID
		name = "1,500 Cash",
		description = "Small bundle",
		price = 0,
		icon = "💵",
		cash = 1500,
	},
	Cash5000 = {
		robloxId = 3477129021,           -- Set to actual product ID
		name = "5,000 Cash",
		description = "Medium bundle",
		price = 0,
		icon = "💰",
		cash = 5000,
	},
	Cash12500 = {
		robloxId = 3477129351,           -- Set to actual product ID
		name = "12,500 Cash",
		description = "Large bundle",
		price = 0,
		icon = "💰",
		cash = 12500,
	},
	Cash30000 = {
		robloxId = 3477129693,           -- Set to actual product ID
		name = "30,000 Cash",
		description = "Mega bundle",
		price = 0,
		icon = "💎",
		cash = 30000,
	},
	Cash75000 = {
		robloxId = 3477130166,           -- Set to actual product ID
		name = "75,000 Cash",
		description = "Ultimate bundle",
		price = 0,
		icon = "💎",
		cash = 75000,
	},
	-- Ability Slot Unlocks
	Slot2 = {
		robloxId = 3477131578,           -- 2nd spin slot product ID
		name = "Slot 2 Unlock",
		description = "Unlock 2nd ability slot",
		price = 0,
		icon = "🎰",
		slotNumber = 2,         -- Which slot this unlocks
	},
	Slot3 = {
		robloxId = 3477131709,           -- 3rd spin slot product ID
		name = "Slot 3 Unlock",
		description = "Unlock 3rd ability slot",
		price = 0,
		icon = "🎰",
		slotNumber = 3,         -- Which slot this unlocks
	},
	-- Lucky Spin Packs (Epic+ only)
	LuckySpin1 = {
		robloxId = 3477131001,           -- 1 Lucky Spin product ID
		name = "1 Lucky Spin",
		description = "1 Epic+ spin!",
		price = 0,
		icon = "🌈",
		luckySpins = 1,         -- Number of spins to give
	},
	LuckySpin3 = {
		robloxId = 3477131167,           -- 3 Lucky Spins product ID
		name = "3 Lucky Spins",
		description = "3 Epic+ spins!",
		price = 0,
		icon = "🌈",
		luckySpins = 3,
	},
	LuckySpin5 = {
		robloxId = 3477131355,           -- 5 Lucky Spins product ID
		name = "5 Lucky Spins",
		description = "5 Epic+ spins!",
		price = 0,
		icon = "🌈",
		luckySpins = 5,
	},
}

-- Order for UI display (cash products only, slots shown separately in StylesPanel)
Purchases.PRODUCT_ORDER = { "Cash500", "Cash1500", "Cash5000", "Cash12500", "Cash30000", "Cash75000" }

-- Slot products order
Purchases.SLOT_ORDER = { "Slot2", "Slot3" }

-- ============== HELPER FUNCTIONS ==============

-- Get gamepass by its string ID
function Purchases.getGamepass(id: string)
	return Purchases.GAMEPASSES[id]
end

-- Get product by its string ID
function Purchases.getProduct(id: string)
	return Purchases.PRODUCTS[id]
end

-- Get gamepass Roblox ID by string ID
function Purchases.getGamepassRobloxId(id: string): number
	local gamepass = Purchases.GAMEPASSES[id]
	return gamepass and gamepass.robloxId or 0
end

-- Get product Roblox ID by string ID
function Purchases.getProductRobloxId(id: string): number
	local product = Purchases.PRODUCTS[id]
	return product and product.robloxId or 0
end

-- Find gamepass by Roblox ID
function Purchases.findGamepassByRobloxId(robloxId: number): (string?, any?)
	for id, gamepass in Purchases.GAMEPASSES do
		if gamepass.robloxId == robloxId then
			return id, gamepass
		end
	end
	return nil, nil
end

-- Find product by Roblox ID
function Purchases.findProductByRobloxId(robloxId: number): (string?, any?)
	for id, product in Purchases.PRODUCTS do
		if product.robloxId == robloxId then
			return id, product
		end
	end
	return nil, nil
end

-- Get slot product by slot number
function Purchases.getSlotProduct(slotNumber: number)
	for _, id in Purchases.SLOT_ORDER do
		local product = Purchases.PRODUCTS[id]
		if product and product.slotNumber == slotNumber then
			return id, product
		end
	end
	return nil, nil
end

-- Get slot product Roblox ID by slot number
function Purchases.getSlotProductRobloxId(slotNumber: number): number
	local _, product = Purchases.getSlotProduct(slotNumber)
	return product and product.robloxId or 0
end

-- Get ordered list of gamepasses for UI
function Purchases.getGamepassList(): { { id: string, [string]: any } }
	local list = {}
	for _, id in Purchases.GAMEPASS_ORDER do
		local gamepass = Purchases.GAMEPASSES[id]
		if gamepass then
			table.insert(list, {
				id = id,
				robloxId = gamepass.robloxId,
				name = gamepass.name,
				description = gamepass.description,
				price = gamepass.price,
				icon = gamepass.icon,
			})
		end
	end
	return list
end

-- Get ordered list of products for UI
function Purchases.getProductList(): { { id: string, [string]: any } }
	local list = {}
	for _, id in Purchases.PRODUCT_ORDER do
		local product = Purchases.PRODUCTS[id]
		if product then
			table.insert(list, {
				id = id,
				robloxId = product.robloxId,
				name = product.name,
				description = product.description,
				price = product.price,
				icon = product.icon,
				cash = product.cash,
			})
		end
	end
	return list
end

return Purchases

