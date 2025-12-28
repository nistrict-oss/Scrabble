local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)

local CurrencyServiceClient = {
	Networker = nil,
	Coins = 0,

	OnCoinsUpdated = Signal.new(),
}

export type CurrencyServiceClient = typeof(CurrencyServiceClient) & {
	Networker: Networker.Client,
}

function CurrencyServiceClient.init(self: CurrencyServiceClient)
	self.Networker = Networker.client.new("CurrencyService", self)

	task.defer(function()
		self.Networker:fire("GetCoins")
	end)
end

function CurrencyServiceClient.CoinsUpdated(
	self: CurrencyServiceClient,
	newCoins: number,
	change: number,
	reason: string
)
	local oldCoins = self.Coins
	self.Coins = newCoins
	self.OnCoinsUpdated:Fire(newCoins, change, reason, oldCoins)
end

function CurrencyServiceClient.getCoins(self: CurrencyServiceClient): number
	return self.Coins
end

function CurrencyServiceClient.canAfford(self: CurrencyServiceClient, amount: number): boolean
	return self.Coins >= amount
end

return CurrencyServiceClient
