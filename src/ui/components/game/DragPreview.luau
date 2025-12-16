--[[
	DragPreview.luau
	
	Floating tile that follows the mouse while dragging a letter.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

-- Letter point values
local LETTER_VALUES = {
	A = 1, B = 3, C = 3, D = 2, E = 1, F = 4, G = 2, H = 4,
	I = 1, J = 8, K = 5, L = 1, M = 3, N = 1, O = 1, P = 3,
	Q = 10, R = 1, S = 1, T = 1, U = 1, V = 4, W = 4, X = 8,
	Y = 4, Z = 10,
}

export type DragPreviewProps = {
	Letter: string?,
}

return function(props: DragPreviewProps)
	local letter = props.Letter
	local mousePos, setMousePos = React.useState(Vector2.new(0, 0))
	
	-- Track mouse position
	React.useEffect(function()
		-- Initial position - GetMouseLocation includes topbar offset
		local initialPos = UserInputService:GetMouseLocation()
		setMousePos(initialPos)
		
		local moveConn = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				-- Use GetMouseLocation for consistency (includes topbar offset)
				local pos = UserInputService:GetMouseLocation()
				setMousePos(pos)
			end
		end)
		
		local touchConn = UserInputService.TouchMoved:Connect(function(_touch)
			local pos = UserInputService:GetMouseLocation()
			setMousePos(pos)
		end)
		
		return function()
			moveConn:Disconnect()
			touchConn:Disconnect()
		end
	end, {})
	
	if not letter then
		return nil
	end
	
	local value = LETTER_VALUES[letter] or 0
	
	return e("Frame", {
		Size = UDim2.fromOffset(50, 50),
		Position = UDim2.fromOffset(mousePos.X, mousePos.Y),
		AnchorPoint = Vector2.new(0.5, 0.5), -- Center on cursor
		BackgroundColor3 = Color3.fromRGB(245, 225, 180),
		ZIndex = 100,
		BorderSizePixel = 0,
	}, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0.15, 0),
		}),
		
		UIStroke = e("UIStroke", {
			Color = Color3.fromRGB(249, 0, 149), -- Pink accent
			Thickness = 3,
		}),
		
		Letter = e("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = letter,
			TextColor3 = Color3.fromRGB(30, 30, 30),
			TextScaled = true,
			FontFace = Font.new(
				"rbxassetid://11702779517",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			ZIndex = 101,
		}, {
			UIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.15, 0),
				PaddingTop = UDim.new(0.1, 0),
				PaddingLeft = UDim.new(0.1, 0),
				PaddingRight = UDim.new(0.1, 0),
			}),
		}),
		
		Value = e("TextLabel", {
			Size = UDim2.fromScale(0.3, 0.3),
			Position = UDim2.fromScale(0.9, 0.9),
			AnchorPoint = Vector2.new(1, 1),
			BackgroundTransparency = 1,
			Text = tostring(value),
			TextColor3 = Color3.fromRGB(80, 80, 80),
			TextScaled = true,
			FontFace = Font.new(
				"rbxassetid://11702779517",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			ZIndex = 101,
		}),
	})
end

