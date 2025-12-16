local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)
local DataService = require(ReplicatedStorage.Packages.DataService).server

local CurrencyServiceServer = {
	Networker = nil,
	OnCashChanged = Signal.new(),
}

export type CurrencyServiceServer = typeof(CurrencyServiceServer) & {
	Networker: Networker.Server,
}

function CurrencyServiceServer.init(self: CurrencyServiceServer)
	self.Networker = Networker.server.new("CurrencyService", self, {
		self.GetCash,
	})
end

-- ============== CASH ==============

function CurrencyServiceServer.getCash(self: CurrencyServiceServer, player: Player): number
	if not DataService:hasProfile(player) then return 0 end
	return DataService:get(player, { "Cash" }) or 0
end

function CurrencyServiceServer.addCash(self: CurrencyServiceServer, player: Player, amount: number, reason: string?): number
	if not DataService:hasProfile(player) then return 0 end
	if amount <= 0 then return self:getCash(player) end
	
	local oldCash = DataService:get(player, { "Cash" }) or 0
	local newCash = oldCash + amount
	
	DataService:set(player, { "Cash" }, newCash)
	DataService:update(player, { "Stats", "CashEarned" }, function(val)
		return (val or 0) + amount
	end)
	
	self.OnCashChanged:Fire(player, newCash, oldCash, amount, reason or "unknown")
	self.Networker:fire({ player }, "CashUpdated", newCash, amount, reason or "unknown")
	
	return newCash
end

function CurrencyServiceServer.removeCash(self: CurrencyServiceServer, player: Player, amount: number, reason: string?): (boolean, number)
	if not DataService:hasProfile(player) then return false, 0 end
	if amount <= 0 then return true, self:getCash(player) end
	
	local oldCash = DataService:get(player, { "Cash" }) or 0
	
	if oldCash < amount then
		return false, oldCash
	end
	
	local newCash = oldCash - amount
	DataService:set(player, { "Cash" }, newCash)
	
	self.OnCashChanged:Fire(player, newCash, oldCash, -amount, reason or "unknown")
	self.Networker:fire({ player }, "CashUpdated", newCash, -amount, reason or "unknown")
	
	return true, newCash
end

function CurrencyServiceServer.setCash(self: CurrencyServiceServer, player: Player, amount: number)
	if not DataService:hasProfile(player) then return end
	
	local oldCash = DataService:get(player, { "Cash" }) or 0
	local newCash = math.max(0, amount)
	
	DataService:set(player, { "Cash" }, newCash)
	
	self.OnCashChanged:Fire(player, newCash, oldCash, newCash - oldCash, "admin_set")
	self.Networker:fire({ player }, "CashUpdated", newCash, newCash - oldCash, "admin_set")
end

function CurrencyServiceServer.canAfford(self: CurrencyServiceServer, player: Player, amount: number): boolean
	return self:getCash(player) >= amount
end

-- ============== NETWORK HANDLERS ==============

function CurrencyServiceServer.GetCash(self: CurrencyServiceServer, player: Player)
	DataService:waitForData(player)
	local cash = self:getCash(player)
	self.Networker:fire({ player }, "CashUpdated", cash, 0, "sync")
end

return CurrencyServiceServer
