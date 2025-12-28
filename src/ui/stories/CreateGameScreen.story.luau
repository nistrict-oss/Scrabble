local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages["React-Roblox"])
local CreateGameScreen = require(ReplicatedStorage.UI.screens.HomeScreen.CreateGameScreen)

return function(target)
	local root = ReactRoblox.createRoot(target)

	local function onClose()
		print("Close requested")
	end

	root:render(React.createElement(CreateGameScreen, {
		OnClose = onClose,
	}))

	return function()
		root:unmount()
	end
end
