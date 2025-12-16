local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)

local CurrencyServiceClient = {
	Networker = nil,
	Cash = 0,
	
	OnCashUpdated = Signal.new(),
}

export type CurrencyServiceClient = typeof(CurrencyServiceClient) & {
	Networker: Networker.Client,
}

function CurrencyServiceClient.init(self: CurrencyServiceClient)
	self.Networker = Networker.client.new("CurrencyService", self)
	
	task.defer(function()
		self.Networker:fire("GetCash")
	end)
end

function CurrencyServiceClient.CashUpdated(self: CurrencyServiceClient, newCash: number, change: number, reason: string)
	local oldCash = self.Cash
	self.Cash = newCash
	self.OnCashUpdated:Fire(newCash, change, reason, oldCash)
end

function CurrencyServiceClient.getCash(self: CurrencyServiceClient): number
	return self.Cash
end

function CurrencyServiceClient.canAfford(self: CurrencyServiceClient, amount: number): boolean
	return self.Cash >= amount
end

return CurrencyServiceClient
