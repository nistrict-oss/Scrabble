local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)

local InventoryServiceClient = {
	Networker = nil,
	
	-- Styles (cosmetic)
	OwnedStyles = {},
	EquippedStyle = nil,
	
	-- Abilities/Styles slot system (what you spin for)
	EquippedAbilities = {}, -- { [slotNumber] = styleId }
	UnlockedSlots = 1,
	ActiveSlot = 1, -- Which slot is selected for use in games
	AbilityDefinitions = {},
	
	-- Lucky Spins (purchased)
	LuckySpins = 0,
	
	-- Style signals
	OnStylesLoaded = Signal.new(),
	OnStyleObtained = Signal.new(),
	OnStyleEquipped = Signal.new(),
	OnStyleUnequipped = Signal.new(),
	
	-- Ability signals
	OnAbilitiesLoaded = Signal.new(),
	OnAbilityEquipped = Signal.new(),
	OnAbilityUnequipped = Signal.new(),
	OnSlotUnlocked = Signal.new(),
	OnActiveSlotChanged = Signal.new(),
	
	-- Spin signals
	OnSpinResult = Signal.new(),
	OnSpinFailed = Signal.new(),
	OnLuckySpinResult = Signal.new(),
	OnLuckySpinFailed = Signal.new(),
	OnLuckySpinsUpdated = Signal.new(),
}

export type InventoryServiceClient = typeof(InventoryServiceClient) & {
	Networker: Networker.Client,
}

function InventoryServiceClient.init(self: InventoryServiceClient)
	self.Networker = Networker.client.new("InventoryService", self)
	
	task.defer(function()
		self.Networker:fire("GetItems")
		self.Networker:fire("GetAbilities")
		self.Networker:fire("GetLuckySpins")
	end)
end

-- ============== STYLE HANDLERS ==============

function InventoryServiceClient.StylesLoaded(self: InventoryServiceClient, styles: {string}, equipped: string?)
	self.OwnedStyles = {}
	for _, styleId in styles do
		self.OwnedStyles[styleId] = true
	end
	self.EquippedStyle = equipped
	
	self.OnStylesLoaded:Fire(styles, equipped)
end

function InventoryServiceClient.StyleObtained(self: InventoryServiceClient, styleId: string)
	self.OwnedStyles[styleId] = true
	self.OnStyleObtained:Fire(styleId)
end

function InventoryServiceClient.StyleEquipped(self: InventoryServiceClient, styleId: string)
	self.EquippedStyle = styleId
	self.OnStyleEquipped:Fire(styleId)
end

function InventoryServiceClient.StyleUnequipped(self: InventoryServiceClient)
	self.EquippedStyle = nil
	self.OnStyleUnequipped:Fire()
end

-- ============== ABILITY HANDLERS ==============

function InventoryServiceClient.AbilitiesLoaded(self: InventoryServiceClient, _abilities: {string}, equippedAbilities: {[number]: string}, unlockedSlots: number, definitions: any, activeSlot: number?)
	self.EquippedAbilities = equippedAbilities or {}
	self.UnlockedSlots = unlockedSlots or 1
	self.ActiveSlot = activeSlot or 1
	self.AbilityDefinitions = definitions or {}
	
	self.OnAbilitiesLoaded:Fire({}, equippedAbilities, unlockedSlots, activeSlot)
end

function InventoryServiceClient.ActiveSlotChanged(self: InventoryServiceClient, slotNumber: number)
	self.ActiveSlot = slotNumber
	self.OnActiveSlotChanged:Fire(slotNumber)
end

function InventoryServiceClient.AbilityEquippedToSlot(self: InventoryServiceClient, slotNumber: number, abilityId: string)
	-- Just set it directly to the slot (replaces whatever was there)
	self.EquippedAbilities[slotNumber] = abilityId
	self.OnAbilityEquipped:Fire(slotNumber, abilityId)
end

function InventoryServiceClient.AbilityUnequippedFromSlot(self: InventoryServiceClient, slotNumber: number)
	self.EquippedAbilities[slotNumber] = nil
	self.OnAbilityUnequipped:Fire(slotNumber)
end

function InventoryServiceClient.SlotUnlocked(self: InventoryServiceClient, newSlotCount: number)
	self.UnlockedSlots = newSlotCount
	self.OnSlotUnlocked:Fire(newSlotCount)
end

-- ============== SPIN HANDLERS ==============

function InventoryServiceClient.SpinResult(self: InventoryServiceClient, itemId: string, itemInfo: any, isDuplicate: boolean, refund: number, isInstant: boolean?)
	self.OnSpinResult:Fire(itemId, itemInfo, isDuplicate, refund, isInstant)
end

function InventoryServiceClient.SpinFailed(self: InventoryServiceClient, reason: string)
	self.OnSpinFailed:Fire(reason)
end

function InventoryServiceClient.LuckySpinResult(self: InventoryServiceClient, itemId: string, itemInfo: any, isDuplicate: boolean, refund: number, isInstant: boolean?)
	self.OnLuckySpinResult:Fire(itemId, itemInfo, isDuplicate, refund, isInstant)
end

function InventoryServiceClient.LuckySpinFailed(self: InventoryServiceClient, reason: string)
	self.OnLuckySpinFailed:Fire(reason)
end

function InventoryServiceClient.LuckySpinsUpdated(self: InventoryServiceClient, count: number)
	self.LuckySpins = count
	self.OnLuckySpinsUpdated:Fire(count)
end

-- ============== STYLE METHODS ==============

function InventoryServiceClient.equipStyle(self: InventoryServiceClient, styleId: string)
	self.Networker:fire("EquipStyle", styleId)
end

function InventoryServiceClient.unequipStyle(self: InventoryServiceClient)
	self.Networker:fire("UnequipStyle")
end

function InventoryServiceClient.ownsStyle(self: InventoryServiceClient, styleId: string): boolean
	return self.OwnedStyles[styleId] == true
end

function InventoryServiceClient.getOwnedStyles(self: InventoryServiceClient): {string}
	local styles = {}
	for styleId in self.OwnedStyles do
		table.insert(styles, styleId)
	end
	return styles
end

-- ============== ABILITY/STYLE SLOT METHODS ==============

function InventoryServiceClient.equipAbilityToSlot(self: InventoryServiceClient, slotNumber: number, abilityId: string)
	self.Networker:fire("EquipAbilityToSlot", slotNumber, abilityId)
end

function InventoryServiceClient.unequipAbilityFromSlot(self: InventoryServiceClient, slotNumber: number)
	self.Networker:fire("UnequipAbilityFromSlot", slotNumber)
end

function InventoryServiceClient.getEquippedAbilities(self: InventoryServiceClient): {[number]: string}
	return self.EquippedAbilities
end

function InventoryServiceClient.getUnlockedSlots(self: InventoryServiceClient): number
	return self.UnlockedSlots
end

function InventoryServiceClient.getActiveSlot(self: InventoryServiceClient): number
	return self.ActiveSlot
end

function InventoryServiceClient.setActiveSlot(self: InventoryServiceClient, slotNumber: number)
	self.ActiveSlot = slotNumber -- Update locally immediately for responsiveness
	self.Networker:fire("SetActiveSlot", slotNumber)
end

function InventoryServiceClient.getAbilityInfo(self: InventoryServiceClient, abilityId: string): any?
	return self.AbilityDefinitions[abilityId]
end

function InventoryServiceClient.spin(self: InventoryServiceClient)
	self.Networker:fire("SpinForAbility")
end

function InventoryServiceClient.useLuckySpin(self: InventoryServiceClient)
	self.Networker:fire("UseLuckySpin")
end

function InventoryServiceClient.getLuckySpins(self: InventoryServiceClient): number
	return self.LuckySpins
end

return InventoryServiceClient
