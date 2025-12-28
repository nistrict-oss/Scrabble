--[[
	NotificationContext.luau
	
	React context for global toast notifications.
	Provides showNotification(message, type) function.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

export type NotificationType = "success" | "error" | "warning" | "info"

export type NotificationData = {
	id: string,
	message: string,
	type: NotificationType,
	duration: number?,
}

export type NotificationContextValue = {
	showNotification: (message: string, type: NotificationType?, duration: number?) -> (),
	notifications: { NotificationData },
	dismissNotification: (id: string) -> (),
}

local NotificationContext = React.createContext(nil :: NotificationContextValue?)

return NotificationContext
