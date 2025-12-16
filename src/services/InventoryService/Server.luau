local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)
local DataService = require(ReplicatedStorage.Packages.DataService).server

local Purchases = require(ReplicatedStorage.Shared.Modules.Game.Purchases)

-- Ability definitions for spinning (built from Abilities config)

local SPIN_COST = 100

local InventoryServiceServer = {
	Networker = nil,
	CurrencyService = nil,
	PurchaseService = nil,
	
	-- Signals
	OnStyleEquipped = Signal.new(),
	OnAbilityObtained = Signal.new(),
	OnAbilityEquipped = Signal.new(),
	OnAbilityUnequipped = Signal.new(),
	OnSlotUnlocked = Signal.new(),
}

export type InventoryServiceServer = typeof(InventoryServiceServer) & {
	Networker: Networker.Server,
}

function InventoryServiceServer.init(self: InventoryServiceServer)
	task.defer(function()
		self.CurrencyService = require(ServerScriptService.Services.CurrencyService.CurrencyServiceServer)
		self.PurchaseService = require(ServerScriptService.Services.PurchaseService.PurchaseServiceServer)
		
		-- Listen for product purchases to handle slot unlocks and lucky spins
		self.PurchaseService.OnProductPurchased:Connect(function(player, _robloxId, productName)
			local product = Purchases.getProduct(productName)
			if product then
				if product.slotNumber then
					local success = self:unlockSlot(player, product.slotNumber)
					if success then
						print(string.format("[InventoryService] Unlocked slot %d for %s via purchase", product.slotNumber, player.Name))
					end
				elseif product.luckySpins then
					-- Add Lucky Spins to player data
					self:addLuckySpins(player, product.luckySpins)
					print(string.format("[InventoryService] Added %d Lucky Spins for %s", product.luckySpins, player.Name))
				end
			end
		end)
	end)
	
	self.Networker = Networker.server.new("InventoryService", self, {
		self.EquipStyle,
		self.UnequipStyle,
		self.EquipAbilityToSlot,
		self.UnequipAbilityFromSlot,
		self.SpinForAbility,
		self.UseLuckySpin,
		self.GetLuckySpins,
		self.SetActiveSlot,
		self.GetItems,
		self.GetAbilities,
	})
end

-- ============== STYLES ==============

function InventoryServiceServer.getOwnedStyles(self: InventoryServiceServer, player: Player): {string}
	if not DataService:hasProfile(player) then return {} end
	
	local ownedStyles = DataService:get(player, { "OwnedStyles" }) or {}
	local styles = {}
	for styleId in ownedStyles do
		table.insert(styles, styleId)
	end
	return styles
end

function InventoryServiceServer.ownsStyle(self: InventoryServiceServer, player: Player, styleId: string): boolean
	if not DataService:hasProfile(player) then return false end
	
	local ownedStyles = DataService:get(player, { "OwnedStyles" }) or {}
	return ownedStyles[styleId] == true
end

function InventoryServiceServer.giveStyle(self: InventoryServiceServer, player: Player, styleId: string): boolean
	if not DataService:hasProfile(player) then return false end
	
	if self:ownsStyle(player, styleId) then
		return false
	end
	
	local ownedStyles = DataService:get(player, { "OwnedStyles" }) or {}
	ownedStyles[styleId] = true
	DataService:set(player, { "OwnedStyles" }, ownedStyles)
	
	self.Networker:fire({ player }, "StyleObtained", styleId)
	
	return true
end

function InventoryServiceServer.equipStyle(self: InventoryServiceServer, player: Player, styleId: string): boolean
	if not DataService:hasProfile(player) then return false end
	
	if not self:ownsStyle(player, styleId) then
		return false
	end
	
	DataService:set(player, { "EquippedStyle" }, styleId)
	
	self.OnStyleEquipped:Fire(player, styleId)
	self.Networker:fire({ player }, "StyleEquipped", styleId)
	
	return true
end

function InventoryServiceServer.unequipStyle(self: InventoryServiceServer, player: Player)
	if not DataService:hasProfile(player) then return end
	
	DataService:set(player, { "EquippedStyle" }, "")
	self.Networker:fire({ player }, "StyleUnequipped")
end

function InventoryServiceServer.getEquippedStyle(self: InventoryServiceServer, player: Player): string?
	if not DataService:hasProfile(player) then return nil end
	
	local equipped = DataService:get(player, { "EquippedStyle" })
	return if equipped and equipped ~= "" then equipped else nil
end

-- ============== ABILITIES (SLOT-BASED) ==============
-- Styles are equipped directly to slots via spinning - no collection system

function InventoryServiceServer.getEquippedAbilities(self: InventoryServiceServer, player: Player): {[number]: string}
	if not DataService:hasProfile(player) then return {} end
	
	return DataService:get(player, { "EquippedAbilities" }) or {}
end

function InventoryServiceServer.getUnlockedSlots(self: InventoryServiceServer, player: Player): number
	if not DataService:hasProfile(player) then return 1 end
	
	return DataService:get(player, { "UnlockedAbilitySlots" }) or AbilitySlots.DEFAULT_SLOTS
end

function InventoryServiceServer.getActiveSlot(self: InventoryServiceServer, player: Player): number
	if not DataService:hasProfile(player) then return 1 end
	
	return DataService:get(player, { "ActiveAbilitySlot" }) or 1
end

function InventoryServiceServer.setActiveSlot(self: InventoryServiceServer, player: Player, slotNumber: number): boolean
	if not DataService:hasProfile(player) then return false end
	
	-- Validate slot number
	if slotNumber < 1 or slotNumber > AbilitySlots.MAX_SLOTS then
		return false
	end
	
	-- Check if slot is unlocked
	local unlockedSlots = self:getUnlockedSlots(player)
	if slotNumber > unlockedSlots then
		return false
	end
	
	DataService:set(player, { "ActiveAbilitySlot" }, slotNumber)
	self.Networker:fire({ player }, "ActiveSlotChanged", slotNumber)
	
	return true
end

function InventoryServiceServer.equipAbilityToSlot(self: InventoryServiceServer, player: Player, slotNumber: number, abilityId: string): boolean
	if not DataService:hasProfile(player) then return false end
	
	-- Validate slot number
	if slotNumber < 1 or slotNumber > AbilitySlots.MAX_SLOTS then
		return false
	end
	
	-- Check if slot is unlocked
	local unlockedSlots = self:getUnlockedSlots(player)
	if slotNumber > unlockedSlots then
		return false
	end
	
	-- Validate ability exists
	if not ABILITY_ITEMS[abilityId] then
		return false
	end
	
	-- Get current equipped abilities and equip to slot (replaces whatever was there)
	local equippedAbilities = DataService:get(player, { "EquippedAbilities" }) or {}
	equippedAbilities[slotNumber] = abilityId
	DataService:set(player, { "EquippedAbilities" }, equippedAbilities)
	
	self.OnAbilityEquipped:Fire(player, slotNumber, abilityId)
	self.Networker:fire({ player }, "AbilityEquippedToSlot", slotNumber, abilityId)
	
	return true
end

function InventoryServiceServer.unequipAbilityFromSlot(self: InventoryServiceServer, player: Player, slotNumber: number): boolean
	if not DataService:hasProfile(player) then return false end
	
	if slotNumber < 1 or slotNumber > AbilitySlots.MAX_SLOTS then
		return false
	end
	
	local equippedAbilities = DataService:get(player, { "EquippedAbilities" }) or {}
	equippedAbilities[slotNumber] = nil
	DataService:set(player, { "EquippedAbilities" }, equippedAbilities)
	
	self.OnAbilityUnequipped:Fire(player, slotNumber)
	self.Networker:fire({ player }, "AbilityUnequippedFromSlot", slotNumber)
	
	return true
end

function InventoryServiceServer.unlockSlot(self: InventoryServiceServer, player: Player, slotNumber: number): boolean
	if not DataService:hasProfile(player) then return false end
	
	if slotNumber < 2 or slotNumber > AbilitySlots.MAX_SLOTS then
		return false
	end
	
	local currentSlots = self:getUnlockedSlots(player)
	if slotNumber <= currentSlots then
		return false -- Already unlocked
	end
	
	-- Only allow unlocking next slot in sequence
	if slotNumber > currentSlots + 1 then
		return false
	end
	
	DataService:set(player, { "UnlockedAbilitySlots" }, slotNumber)
	
	self.OnSlotUnlocked:Fire(player, slotNumber)
	self.Networker:fire({ player }, "SlotUnlocked", slotNumber)
	
	return true
end

-- Get ability for gameplay (returns first equipped ability or default)
function InventoryServiceServer.getActiveAbility(self: InventoryServiceServer, player: Player, slotNumber: number?): any
	if not DataService:hasProfile(player) then return Abilities.default end
	
	local equippedAbilities = self:getEquippedAbilities(player)
	local slot = slotNumber or 1
	local abilityId = equippedAbilities[slot]
	
	if abilityId and Abilities[abilityId] then
		return Abilities[abilityId]
	end
	
	return Abilities.default
end

-- ============== SPINNING ==============

-- Rarity tiers for LuckySpins bonus (Rare and above get 2x chance)
local LUCKY_RARITIES = {
	Rare = true,
	Epic = true,
	Legendary = true,
	Mathematic = true,
}

-- Rarity tiers for Lucky Spin product (Epic+ only)
local LUCKY_SPIN_RARITIES = {
	Epic = true,
	Legendary = true,
	Mathematic = true,
}

function InventoryServiceServer.spin(self: InventoryServiceServer, player: Player): (boolean, string?, any?)
	if not DataService:hasProfile(player) or not self.CurrencyService then 
		return false, nil, nil 
	end
	
	local cash = self.CurrencyService:getCash(player)
	if cash < SPIN_COST then
		self.Networker:fire({ player }, "SpinFailed", "NotEnoughCash")
		return false, nil, nil
	end
	
	self.CurrencyService:removeCash(player, SPIN_COST, "spin")
	
	-- Check for LuckySpins (2x chance for Rare+ styles)
	local hasLuckySpins = self.PurchaseService and self.PurchaseService:hasLuckySpins(player)
	
	-- Build chances table, applying LuckySpins bonus
	local adjustedChances = {}
	local totalChance = 0
	
	for _, styleId in ipairs(Abilities.SPINNABLE) do
		local ability = Abilities[styleId]
		if ability and ability.chance then
			local chance = ability.chance
			-- Double the chance for Rare+ if player has LuckySpins
			if hasLuckySpins and LUCKY_RARITIES[ability.rarity] then
				chance = chance * 2
			end
			adjustedChances[styleId] = chance
			totalChance += chance
		end
	end
	
	-- Roll using adjusted chances
	local roll = math.random() * totalChance
	local cumulative = 0
	local selectedItemId = "basic" -- Default fallback
	
	for _, styleId in ipairs(Abilities.SPINNABLE) do
		local chance = adjustedChances[styleId]
		if chance then
			cumulative += chance
			if roll <= cumulative then
				selectedItemId = styleId
				break
			end
		end
	end
	
	local selectedItem = ABILITY_ITEMS[selectedItemId]
	
	-- Check if player has InstantSpin gamepass
	local hasInstantSpin = self.PurchaseService and self.PurchaseService:hasInstantSpin(player)
	
	-- Send result to client with instant spin flag
	self.Networker:fire({ player }, "SpinResult", selectedItemId, selectedItem, false, 0, hasInstantSpin)
	
	return true, selectedItemId, selectedItem
end

-- ============== LUCKY SPINS ==============

-- Get Lucky Spins count
function InventoryServiceServer.getLuckySpins(self: InventoryServiceServer, player: Player): number
	if not DataService:hasProfile(player) then return 0 end
	return DataService:get(player, { "LuckySpins" }) or 0
end

-- Add Lucky Spins to player
function InventoryServiceServer.addLuckySpins(self: InventoryServiceServer, player: Player, amount: number)
	if not DataService:hasProfile(player) then return end
	local current = self:getLuckySpins(player)
	DataService:set(player, { "LuckySpins" }, current + amount)
	self.Networker:fire({ player }, "LuckySpinsUpdated", current + amount)
end

-- Use a Lucky Spin
function InventoryServiceServer.useLuckySpin(self: InventoryServiceServer, player: Player): boolean
	if not DataService:hasProfile(player) then return false end
	local current = self:getLuckySpins(player)
	if current <= 0 then return false end
	DataService:set(player, { "LuckySpins" }, current - 1)
	self.Networker:fire({ player }, "LuckySpinsUpdated", current - 1)
	return true
end

-- Lucky Spin: Only Epic, Legendary, and Mathematic rarities (uses owned Lucky Spins)
function InventoryServiceServer.luckySpin(self: InventoryServiceServer, player: Player): (boolean, string?, any?)
	if not DataService:hasProfile(player) then 
		self.Networker:fire({ player }, "LuckySpinFailed", "NoData")
		return false, nil, nil 
	end
	
	-- Check if player has Lucky Spins
	if not self:useLuckySpin(player) then
		self.Networker:fire({ player }, "LuckySpinFailed", "NoLuckySpins")
		return false, nil, nil
	end
	
	-- Build chances table for Epic+ only
	local adjustedChances = {}
	local totalChance = 0
	
	for _, styleId in ipairs(Abilities.SPINNABLE) do
		local ability = Abilities[styleId]
		if ability and ability.chance and LUCKY_SPIN_RARITIES[ability.rarity] then
			adjustedChances[styleId] = ability.chance
			totalChance += ability.chance
		end
	end
	
	-- Roll using adjusted chances
	local roll = math.random() * totalChance
	local cumulative = 0
	local selectedItemId = nil
	
	for _, styleId in ipairs(Abilities.SPINNABLE) do
		local chance = adjustedChances[styleId]
		if chance then
			cumulative += chance
			if roll <= cumulative then
				selectedItemId = styleId
				break
			end
		end
	end
	
	-- Fallback to first Epic+ if somehow nothing selected
	if not selectedItemId then
		for _, styleId in ipairs(Abilities.SPINNABLE) do
			local ability = Abilities[styleId]
			if ability and LUCKY_SPIN_RARITIES[ability.rarity] then
				selectedItemId = styleId
				break
			end
		end
	end
	
	local selectedItem = ABILITY_ITEMS[selectedItemId]
	
	-- Check if player has InstantSpin gamepass
	local hasInstantSpin = self.PurchaseService and self.PurchaseService:hasInstantSpin(player)
	
	-- Send result to client with lucky spin flag
	self.Networker:fire({ player }, "LuckySpinResult", selectedItemId, selectedItem, false, 0, hasInstantSpin)
	
	return true, selectedItemId, selectedItem
end

-- ============== NETWORK HANDLERS ==============

function InventoryServiceServer.EquipStyle(self: InventoryServiceServer, player: Player, styleId: string)
	self:equipStyle(player, styleId)
end

function InventoryServiceServer.UnequipStyle(self: InventoryServiceServer, player: Player)
	self:unequipStyle(player)
end

function InventoryServiceServer.EquipAbilityToSlot(self: InventoryServiceServer, player: Player, slotNumber: number, abilityId: string)
	self:equipAbilityToSlot(player, slotNumber, abilityId)
end

function InventoryServiceServer.UnequipAbilityFromSlot(self: InventoryServiceServer, player: Player, slotNumber: number)
	self:unequipAbilityFromSlot(player, slotNumber)
end

function InventoryServiceServer.SpinForAbility(self: InventoryServiceServer, player: Player)
	self:spin(player)
end

function InventoryServiceServer.UseLuckySpin(self: InventoryServiceServer, player: Player)
	self:luckySpin(player)
end

function InventoryServiceServer.GetLuckySpins(self: InventoryServiceServer, player: Player)
	DataService:waitForData(player)
	local luckySpins = self:getLuckySpins(player)
	self.Networker:fire({ player }, "LuckySpinsUpdated", luckySpins)
end

function InventoryServiceServer.GetItems(self: InventoryServiceServer, player: Player)
	DataService:waitForData(player)
	local styles = self:getOwnedStyles(player)
	local equippedStyle = self:getEquippedStyle(player)
	self.Networker:fire({ player }, "StylesLoaded", styles, equippedStyle)
end

function InventoryServiceServer.GetAbilities(self: InventoryServiceServer, player: Player)
	DataService:waitForData(player)
	local equippedAbilities = self:getEquippedAbilities(player)
	local unlockedSlots = self:getUnlockedSlots(player)
	local activeSlot = self:getActiveSlot(player)
	self.Networker:fire({ player }, "AbilitiesLoaded", {}, equippedAbilities, unlockedSlots, ABILITY_ITEMS, activeSlot)
end

function InventoryServiceServer.SetActiveSlot(self: InventoryServiceServer, player: Player, slotNumber: number)
	self:setActiveSlot(player, slotNumber)
end

InventoryServiceServer.ABILITY_ITEMS = ABILITY_ITEMS
InventoryServiceServer.RARITIES = RARITIES
InventoryServiceServer.SPIN_COST = SPIN_COST

return InventoryServiceServer
