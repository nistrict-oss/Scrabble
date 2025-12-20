--[[
	WordValidationDisplay.luau
	
	Shows the current word being formed and whether it's valid.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

export type WordValidationDisplayProps = {
	Word: string,
	IsValid: boolean,
	Score: number,
	Direction: "across" | "down" | "none",
	Multipliers: { string }?,
	Error: string?,
	InvalidWords: { string }?,
}

return function(props: WordValidationDisplayProps)
	local word = props.Word or ""
	local isValid = props.IsValid
	local score = props.Score or 0
	local direction = props.Direction or "none"
	local errorMsg = props.Error
	local multipliers = props.Multipliers or {}
	local invalidWords = props.InvalidWords or {}
	if #word == 0 and not errorMsg and #invalidWords == 0 then
		return e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			Hint = e("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "Place tiles to form a word",
				TextColor3 = Color3.fromRGB(150, 150, 180),
				TextScaled = true,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium, Enum.FontStyle.Italic),
			}, {
				UIPadding = e("UIPadding", {
					PaddingLeft = UDim.new(0.05, 0),
					PaddingRight = UDim.new(0.05, 0),
				}),
			}),
		})
	end

	local bgColor = isValid and Color3.fromRGB(40, 100, 50) or Color3.fromRGB(100, 40, 40)

	local statusIcon = isValid and "✓" or "X"
	local statusText
	if isValid then
		statusText = word .. " (" .. score .. " pts)"
		if #multipliers > 0 then
			statusText = statusText .. " • " .. table.concat(multipliers, ", ")
		end
	elseif #invalidWords > 0 then
		statusText = "Invalid: " .. table.concat(invalidWords, ", ")
	elseif errorMsg then
		statusText = errorMsg
	else
		statusText = word .. " - Invalid"
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = bgColor,
		ClipsDescendants = true,
	}, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0.3, 0),
		}),

		UIStroke = e("UIStroke", {
			Color = isValid and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100),
			Thickness = 2,
		}),

		Content = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			UIListLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0.02, 0),
			}),

			Icon = e("TextLabel", {
				Size = UDim2.fromScale(0.15, 0.8),
				BackgroundTransparency = 1,
				Text = statusIcon,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				LayoutOrder = 1,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			}),

			WordText = e("TextLabel", {
				Size = UDim2.fromScale(0.7, 0.8),
				BackgroundTransparency = 1,
				Text = statusText,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 2,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			}),

			DirectionIcon = direction ~= "none" and e("TextLabel", {
				Size = UDim2.fromScale(0.1, 0.8),
				BackgroundTransparency = 1,
				Text = direction == "across" and "→" or "↓",
				TextColor3 = Color3.fromRGB(200, 200, 220),
				TextScaled = true,
				LayoutOrder = 3,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
			}) or nil,
		}),
	})
end
