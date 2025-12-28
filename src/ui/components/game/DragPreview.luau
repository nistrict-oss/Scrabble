--[[
	DragPreview.luau
	
	Floating tile that follows the mouse while dragging a letter.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LetterTile = require(ReplicatedStorage.UI.components.game.LetterTile)
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

export type DragPreviewProps = {
	Letter: string?,
}

return function(props: DragPreviewProps)
	local letter = props.Letter
	local mousePos, setMousePos = React.useBinding(Vector2.new(0, 0))

	-- Track input position
	React.useEffect(function()
		local connection = game:GetService("RunService").RenderStepped:Connect(function()
			local pos = UserInputService:GetMouseLocation()
			setMousePos(pos)
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	if not letter then
		return nil
	end

	return e("ScreenGui", {
		DisplayOrder = 1000,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {
		PreviewFrame = e("Frame", {
			Size = UDim2.fromOffset(70, 70), -- Standard tile size for drag preview
			Position = mousePos:map(function(pos)
				return UDim2.fromOffset(pos.X, pos.Y)
			end),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
		}, {
			Tile = e(LetterTile, {
				Letter = letter,
				Index = 0,
				IsDisabled = false,
				NoPop = true,
				Active = false, -- Prevent clicks on the preview itself
			}),
		}),
	})
end
