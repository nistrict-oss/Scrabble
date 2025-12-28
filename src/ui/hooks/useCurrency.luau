--[[
	useCurrency.luau
	
	Hook to subscribe to the player's Coin balance.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local CurrencyServiceClient = require(ReplicatedStorage.Shared.Services.CurrencyService.CurrencyServiceClient)

local function useCurrency()
	local coins, setCoins = React.useState(CurrencyServiceClient.Coins)

	React.useEffect(function()
		local conn = CurrencyServiceClient.OnCoinsUpdated:Connect(function(newCoins)
			setCoins(newCoins)
		end)

		-- Sync initial value just in case
		setCoins(CurrencyServiceClient.Coins)

		return function()
			conn:Disconnect()
		end
	end, {})

	return coins
end

return useCurrency
