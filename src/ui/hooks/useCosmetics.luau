local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local InventoryServiceClient = require(ReplicatedStorage.Shared.Services.InventoryService.InventoryServiceClient)
local Colors = require(ReplicatedStorage.Shared.Modules.Game.Colors)

local function useCosmetics()
	local equipped, setEquipped = React.useState(InventoryServiceClient.EquippedColors)
	local owned, setOwned = React.useState(InventoryServiceClient.OwnedTileColors)

	React.useEffect(function()
		local conn = InventoryServiceClient.OnTileColorsLoaded:Connect(function(newOwned, newEquipped)
			setOwned(newOwned)
			setEquipped(newEquipped)
		end)

		local equipConn = InventoryServiceClient.OnTileColorEquipped:Connect(function(slot, colorId)
			setEquipped(function(prev)
				local nextEquipped = table.clone(prev)
				nextEquipped[slot] = colorId
				return nextEquipped
			end)
		end)

		-- Subscribe to purchase signal so shop updates when buying colors
		local purchaseConn = InventoryServiceClient.OnTileColorPurchased:Connect(function(colorId)
			setOwned(function(prev)
				local nextOwned = table.clone(prev)
				table.insert(nextOwned, colorId)
				return nextOwned
			end)
		end)

		return function()
			conn:Disconnect()
			equipConn:Disconnect()
			purchaseConn:Disconnect()
		end
	end, {})

	local equippedColors = {
		Tile = Colors.getColor(equipped.Tile).Value,
		Text = Colors.getColor(equipped.Text).Value,
		Stroke = Colors.getColor(equipped.Stroke).Value,
	}

	return {
		Owned = owned,
		Equipped = equipped, -- IDs
		EquippedColors = equippedColors, -- Color3 objects
		Equip = function(slot: string, colorId: string)
			InventoryServiceClient:equipTileColor(slot, colorId)
		end,
		Buy = function(colorId: string)
			InventoryServiceClient:buyTileColor(colorId)
		end,
	}
end

return useCosmetics
