local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)
local DataService = require(ReplicatedStorage.Packages.DataService).server

local CurrencyServiceServer = {
	Networker = nil,
	OnCoinsChanged = Signal.new(),
}

export type CurrencyServiceServer = typeof(CurrencyServiceServer) & {
	Networker: Networker.Server,
}

function CurrencyServiceServer.init(self: CurrencyServiceServer)
	self.Networker = Networker.server.new("CurrencyService", self, {
		self.GetCoins,
	})
end

-- ============== COINS ==============

function CurrencyServiceServer.getCoins(self: CurrencyServiceServer, player: Player): number
	if not DataService:hasProfile(player) then
		return 0
	end
	return DataService:get(player, { "Coins" }) or 0
end

function CurrencyServiceServer.addCoins(
	self: CurrencyServiceServer,
	player: Player,
	amount: number,
	reason: string?
): number
	if not DataService:hasProfile(player) then
		return 0
	end
	if amount <= 0 then
		return self:getCoins(player)
	end

	local oldCoins = DataService:get(player, { "Coins" }) or 0
	local newCoins = oldCoins + amount

	DataService:set(player, { "Coins" }, newCoins)
	DataService:update(player, { "Stats", "CoinsEarned" }, function(val)
		return (val or 0) + amount
	end)

	self.OnCoinsChanged:Fire(player, newCoins, oldCoins, amount, reason or "unknown")
	self.Networker:fire({ player }, "CoinsUpdated", newCoins, amount, reason or "unknown")

	return newCoins
end

function CurrencyServiceServer.removeCoins(
	self: CurrencyServiceServer,
	player: Player,
	amount: number,
	reason: string?
): (boolean, number)
	if not DataService:hasProfile(player) then
		return false, 0
	end
	if amount <= 0 then
		return true, self:getCoins(player)
	end

	local oldCoins = DataService:get(player, { "Coins" }) or 0

	if oldCoins < amount then
		return false, oldCoins
	end

	local newCoins = oldCoins - amount
	DataService:set(player, { "Coins" }, newCoins)

	self.OnCoinsChanged:Fire(player, newCoins, oldCoins, -amount, reason or "unknown")
	self.Networker:fire({ player }, "CoinsUpdated", newCoins, -amount, reason or "unknown")

	return true, newCoins
end

function CurrencyServiceServer.setCoins(self: CurrencyServiceServer, player: Player, amount: number)
	if not DataService:hasProfile(player) then
		return
	end

	local oldCoins = DataService:get(player, { "Coins" }) or 0
	local newCoins = math.max(0, amount)

	DataService:set(player, { "Coins" }, newCoins)

	self.OnCoinsChanged:Fire(player, newCoins, oldCoins, newCoins - oldCoins, "admin_set")
	self.Networker:fire({ player }, "CoinsUpdated", newCoins, newCoins - oldCoins, "admin_set")
end

function CurrencyServiceServer.canAfford(self: CurrencyServiceServer, player: Player, amount: number): boolean
	return self:getCoins(player) >= amount
end

-- ============== NETWORK HANDLERS ==============

function CurrencyServiceServer.GetCoins(self: CurrencyServiceServer, player: Player)
	DataService:waitForData(player)
	local coins = self:getCoins(player)
	self.Networker:fire({ player }, "CoinsUpdated", coins, 0, "sync")
end

return CurrencyServiceServer
