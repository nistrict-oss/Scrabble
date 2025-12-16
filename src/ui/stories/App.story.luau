local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages["React-Roblox"])
local App = require(ReplicatedStorage.UI.App)

return function(target)
	local root = ReactRoblox.createRoot(target)
	root:render(React.createElement(App))
	return function()
		root:unmount()
	end
end
