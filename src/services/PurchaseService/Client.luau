local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)

local PurchaseServiceClient = {
	Networker = nil,
	OwnedGamepasses = {},
	OwnedGamepassNames = {},
	ActiveBoosts = {},
	
	-- Prices fetched from server (via MarketplaceService)
	GamepassPrices = {}, -- { [gamepassName] = price }
	ProductPrices = {},  -- { [productName] = price }
	
	OnGamepassesLoaded = Signal.new(),
	OnGamepassPurchased = Signal.new(),
	OnProductPurchased = Signal.new(),
	OnPurchaseFailed = Signal.new(),
	OnBoostActivated = Signal.new(),
	OnPricesLoaded = Signal.new(),
	OnGiftSent = Signal.new(), -- Fired when a gift is successfully sent
	OnDonationReceived = Signal.new(), -- Fired when a donation is completed
}

export type PurchaseServiceClient = typeof(PurchaseServiceClient) & {
	Networker: Networker.Client,
}

function PurchaseServiceClient.init(self: PurchaseServiceClient)
	self.Networker = Networker.client.new("PurchaseService", self)
	
	task.defer(function()
		self.Networker:fire("GetOwnedGamepasses")
		self.Networker:fire("GetPrices")
	end)
end

function PurchaseServiceClient.GamepassesLoaded(self: PurchaseServiceClient, ownedList: { string })
	self.OwnedGamepasses = {}
	self.OwnedGamepassNames = {}
	-- Server sends a list of gamepass names (strings)
	local list = ownedList or {}
	for _, gamepassName in list do
		self.OwnedGamepassNames[gamepassName] = true
	end
	self.OnGamepassesLoaded:Fire(ownedList)
end

function PurchaseServiceClient.GamepassPurchased(self: PurchaseServiceClient, gamepassId: number, gamepassName: string)
	self.OwnedGamepasses[gamepassId] = true
	self.OwnedGamepassNames[gamepassName] = true
	self.OnGamepassPurchased:Fire(gamepassId, gamepassName)
end

function PurchaseServiceClient.PurchaseFailed(self: PurchaseServiceClient, reason: string)
	self.OnPurchaseFailed:Fire(reason)
end

function PurchaseServiceClient.ProductPurchased(self: PurchaseServiceClient, productId: number, productName: string)
	self.OnProductPurchased:Fire(productId, productName)
end

function PurchaseServiceClient.BoostActivated(self: PurchaseServiceClient, boostName: string, duration: number)
	self.ActiveBoosts[boostName] = os.time() + duration
	self.OnBoostActivated:Fire(boostName, duration)
end

function PurchaseServiceClient.GiftSent(self: PurchaseServiceClient, itemName: string, recipientName: string)
	self.OnGiftSent:Fire(itemName, recipientName)
end

function PurchaseServiceClient.DonationReceived(self: PurchaseServiceClient, productId: number, robuxAmount: number)
	self.OnDonationReceived:Fire(productId, robuxAmount)
end

function PurchaseServiceClient.PricesLoaded(self: PurchaseServiceClient, gamepassPrices: { [string]: number }, productPrices: { [string]: number })
	self.GamepassPrices = gamepassPrices or {}
	self.ProductPrices = productPrices or {}
	self.OnPricesLoaded:Fire(gamepassPrices, productPrices)
end

function PurchaseServiceClient.getGamepassPrice(self: PurchaseServiceClient, gamepassName: string): number
	return self.GamepassPrices[gamepassName] or 0
end

function PurchaseServiceClient.getProductPrice(self: PurchaseServiceClient, productName: string): number
	return self.ProductPrices[productName] or 0
end

function PurchaseServiceClient.requestPrices(self: PurchaseServiceClient)
	if self.Networker then
		self.Networker:fire("GetPrices")
	end
end

function PurchaseServiceClient.promptGamepass(self: PurchaseServiceClient, gamepassName: string)
	if self.Networker then
		self.Networker:fire("PromptGamepass", gamepassName)
	end
end

function PurchaseServiceClient.promptProduct(self: PurchaseServiceClient, productName: string)
	if self.Networker then
		self.Networker:fire("PromptProduct", productName)
	end
end

function PurchaseServiceClient.promptGiftGamepass(self: PurchaseServiceClient, gamepassName: string, recipientPlayer: Player)
	if self.Networker and recipientPlayer then
		self.Networker:fire("PromptGiftGamepass", gamepassName, recipientPlayer.UserId)
	end
end

function PurchaseServiceClient.promptGiftProduct(self: PurchaseServiceClient, productName: string, recipientPlayer: Player)
	if self.Networker and recipientPlayer then
		self.Networker:fire("PromptGiftProduct", productName, recipientPlayer.UserId)
	end
end

function PurchaseServiceClient.ownsGamepass(self: PurchaseServiceClient, gamepassId: number): boolean
	return self.OwnedGamepasses[gamepassId] == true
end

function PurchaseServiceClient.ownsGamepassByName(self: PurchaseServiceClient, gamepassName: string): boolean
	return self.OwnedGamepassNames[gamepassName] == true
end

function PurchaseServiceClient.getOwnedGamepasses(self: PurchaseServiceClient): { [string]: boolean }
	return self.OwnedGamepassNames
end

function PurchaseServiceClient.hasBoost(self: PurchaseServiceClient, boostName: string): boolean
	local endTime = self.ActiveBoosts[boostName]
	return endTime and os.time() < endTime
end

return PurchaseServiceClient
