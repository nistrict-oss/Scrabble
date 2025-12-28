--[[
	BlankTileModal.luau
	
	Modal for choosing a letter for a blank tile.
	Shows an alphabet grid for the player to select.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)

local e = React.createElement

local ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

export type BlankTileModalProps = {
	OnSelect: (letter: string) -> (),
	OnCancel: () -> (),
}

return function(props: BlankTileModalProps)
	-- Build letter buttons
	local letterButtons = {}
	for i = 1, #ALPHABET do
		local letter = ALPHABET:sub(i, i)
		letterButtons["Letter_" .. letter] = e("TextButton", {
			Size = UDim2.fromScale(1 / 7, 0.9),
			BackgroundColor3 = Color3.fromRGB(60, 70, 100),
			LayoutOrder = i,
			Text = letter,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
			[React.Event.Activated] = function()
				props.OnSelect(letter)
			end,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0.15, 0) }),
			UIStroke = e("UIStroke", {
				Color = Color3.fromRGB(100, 120, 180),
				Thickness = 2,
			}),
			UIAspectRatioConstraint = e("UIAspectRatioConstraint", { AspectRatio = 1 }),
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.4,
		ZIndex = 1000,
	}, {
		Modal = e("Frame", {
			Size = UDim2.fromScale(0.5, 0.4),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(30, 40, 60),
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0.03, 0) }),
			UIStroke = e("UIStroke", {
				Color = Color3.fromRGB(200, 200, 255),
				Thickness = 3,
			}),
			UIPadding = e("UIPadding", {
				PaddingTop = UDim.new(0.05, 0),
				PaddingBottom = UDim.new(0.05, 0),
				PaddingLeft = UDim.new(0.05, 0),
				PaddingRight = UDim.new(0.05, 0),
			}),

			Header = e("TextLabel", {
				Size = UDim2.fromScale(1, 0.15),
				Position = UDim2.fromScale(0, 0),
				BackgroundTransparency = 1,
				Text = "Choose a Letter",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy),
			}),

			LetterGrid = e(
				"Frame",
				{
					Size = UDim2.fromScale(1, 0.65),
					Position = UDim2.fromScale(0, 0.18),
					BackgroundTransparency = 1,
				},
				(function()
					local gridChildren = {
						UIGridLayout = e("UIGridLayout", {
							CellSize = UDim2.fromScale(1 / 7 - 0.01, 0.22),
							CellPadding = UDim2.fromScale(0.01, 0.02),
							SortOrder = Enum.SortOrder.LayoutOrder,
						}),
					}
					for key, value in pairs(letterButtons) do
						gridChildren[key] = value
					end
					return gridChildren
				end)()
			),

			CancelButton = e(TextButton, {
				Text = "Cancel",
				Variant = "secondary",
				Size = UDim2.fromScale(0.3, 0.12),
				Position = UDim2.fromScale(0.5, 0.95),
				AnchorPoint = Vector2.new(0.5, 1),
				OnClick = props.OnCancel,
			}),
		}),
	})
end
