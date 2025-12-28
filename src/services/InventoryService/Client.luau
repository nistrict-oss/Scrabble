local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)

local InventoryServiceClient = {
	Networker = nil,

	-- Tile Cosmetics
	OwnedTileColors = {},
	EquippedColors = { Tile = "tan", Text = "coal", Stroke = "tan" },

	-- Tile color signals
	OnTileColorsLoaded = Signal.new(),
	OnTileColorEquipped = Signal.new(),
	OnTileColorPurchased = Signal.new(),
}

export type InventoryServiceClient = typeof(InventoryServiceClient) & {
	Networker: Networker.Client,
}

function InventoryServiceClient.init(self: InventoryServiceClient)
	self.Networker = Networker.client.new("InventoryService", self)

	task.defer(function()
		self.Networker:fire("GetOwnedTileColors")
	end)
end

function InventoryServiceClient.TileColorsLoaded(
	self: InventoryServiceClient,
	owned: { string },
	equipped: { Tile: string, Text: string, Stroke: string }
)
	self.OwnedTileColors = owned
	self.EquippedColors = equipped or { Tile = "tan", Text = "coal", Stroke = "tan" }
	self.OnTileColorsLoaded:Fire(owned, equipped)
end

function InventoryServiceClient.TileColorEquipped(self: InventoryServiceClient, slot: string, colorId: string)
	self.EquippedColors[slot] = colorId
	self.OnTileColorEquipped:Fire(slot, colorId)
end

function InventoryServiceClient.TileColorPurchased(self: InventoryServiceClient, colorId: string)
	table.insert(self.OwnedTileColors, colorId)
	self.OnTileColorPurchased:Fire(colorId)
end

-- ============== TILE COLOR METHODS ==============

function InventoryServiceClient.equipTileColor(self: InventoryServiceClient, slot: string, colorId: string)
	self.Networker:fire("EquipTileColor", slot, colorId)
end

function InventoryServiceClient.buyTileColor(self: InventoryServiceClient, colorId: string)
	self.Networker:fire("BuyTileColor", colorId)
end

function InventoryServiceClient.getOwnedTileColors(self: InventoryServiceClient): { string }
	return self.OwnedTileColors
end

function InventoryServiceClient.getEquippedColors(self: InventoryServiceClient)
	return self.EquippedColors
end

return InventoryServiceClient
