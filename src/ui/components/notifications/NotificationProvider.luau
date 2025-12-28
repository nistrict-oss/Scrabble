--[[
	NotificationProvider.luau
	
	Provider component that wraps the app and manages toast notifications.
	Renders notifications and provides context for showing new ones.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local React = require(ReplicatedStorage.Packages.React)
local NotificationContext = require(ReplicatedStorage.UI.contexts.NotificationContext)

local e = React.createElement

return function(props)
	local notifications, setNotifications = React.useState({} :: { NotificationContext.NotificationData })

	local showNotification = React.useCallback(
		function(message: string, notifType: NotificationContext.NotificationType?, duration: number?)
			local id = HttpService:GenerateGUID(false)
			local actualType = notifType or "info"
			local actualDuration = duration or 3

			setNotifications(function(prev)
				local next = table.clone(prev)
				table.insert(next, {
					id = id,
					message = message,
					type = actualType,
					duration = actualDuration,
				})
				return next
			end)

			-- Auto-dismiss after duration
			task.delay(actualDuration, function()
				setNotifications(function(prev)
					local next = {}
					for _, n in ipairs(prev) do
						if n.id ~= id then
							table.insert(next, n)
						end
					end
					return next
				end)
			end)
		end,
		{}
	)

	local dismissNotification = React.useCallback(function(id: string)
		setNotifications(function(prev)
			local next = {}
			for _, n in ipairs(prev) do
				if n.id ~= id then
					table.insert(next, n)
				end
			end
			return next
		end)
	end, {})

	local contextValue: NotificationContext.NotificationContextValue = {
		showNotification = showNotification,
		notifications = notifications,
		dismissNotification = dismissNotification,
	}

	-- Just pass through children like ScrabbleProvider does
	return e(NotificationContext.Provider, {
		value = contextValue,
	}, props.children)
end
