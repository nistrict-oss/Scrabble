--[[
	NotificationContainer.luau
	
	Component that renders toast notifications.
	Should be placed at the top level of the app.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local useNotification = require(ReplicatedStorage.UI.hooks.useNotification)
local ToastNotification = require(ReplicatedStorage.UI.components.notifications.ToastNotification)

local e = React.createElement

return function()
	local notification = useNotification()
	local notifications = notification.notifications
	local dismissNotification = notification.dismissNotification

	-- Build notification elements
	local notificationElements = {}
	for i, notif in ipairs(notifications) do
		notificationElements[notif.id] = e(ToastNotification, {
			Message = notif.message,
			Type = notif.type,
			Index = i,
			OnDismiss = function()
				dismissNotification(notif.id)
			end,
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 100,
	}, notificationElements)
end
