local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages["React-Roblox"])
local EndGameAnnouncement = require(ReplicatedStorage.UI.components.game.EndGameAnnouncement)

local LocalPlayer = Players.LocalPlayer

return function(target)
	local root = ReactRoblox.createRoot(target)

	-- Show the end game announcement (just the swooping text)
	root:render(React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(45, 65, 115), -- Match game background
	}, {
		EndGameAnnouncement = React.createElement(EndGameAnnouncement, {
			PlayerName = LocalPlayer and LocalPlayer.Name or "PlayerOne",
		}),
	}))

	return function()
		root:unmount()
	end
end
