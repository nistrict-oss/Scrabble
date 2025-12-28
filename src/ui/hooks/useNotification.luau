--[[
	useNotification.luau
	
	React hook to access the notification context.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local NotificationContext = require(ReplicatedStorage.UI.contexts.NotificationContext)

local function useNotification()
	local context = React.useContext(NotificationContext)
	if not context then
		-- Return a no-op if not wrapped in provider (for safety)
		return {
			showNotification = function() end,
			notifications = {},
			dismissNotification = function() end,
		}
	end
	return context
end

return useNotification
