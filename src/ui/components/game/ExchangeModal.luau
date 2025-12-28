--[[
	ExchangeModal.luau
	
	A themed modal for selecting tiles to exchange.
	Includes a "Bag Info" panel showing letter distribution.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local LetterTile = require(ReplicatedStorage.UI.components.game.LetterTile)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)
local ScrabbleConfig = require(ReplicatedStorage.Shared.Modules.Game.ScrabbleConfig)

local e = React.createElement

export type ExchangeModalProps = {
	Letters: { { id: number, letter: string } }, -- Current hand
	Selection: { [number]: boolean }, -- Selected rack indices
	OnToggle: (rackIndex: number) -> (),
	OnConfirm: () -> (),
	OnCancel: () -> (),
}

return function(props: ExchangeModalProps)
	local letters = props.Letters
	local selection = props.Selection
	local selectedCount = 0
	for _, s in pairs(selection) do
		if s then
			selectedCount += 1
		end
	end

	-- Bag Distribution Info
	local distribution = {}
	for _, item in ipairs(ScrabbleConfig.LETTERS) do
		table.insert(distribution, {
			Letter = item.letter,
			Count = item.count,
			Value = item.value,
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,
		ZIndex = 1000,
	}, {
		e("Frame", {
			key = "Container",
			Size = UDim2.fromScale(0.7, 0.7),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(30, 40, 70),
			BorderSizePixel = 0,
		}, {
			e("UICorner", { key = "UICorner", CornerRadius = UDim.new(0.04, 0) }),
			e("UIStroke", { key = "UIStroke", Color = Color3.fromRGB(249, 0, 149), Thickness = 4 }),

			e("TextLabel", {
				key = "Title",
				Size = UDim2.fromScale(1, 0.15),
				BackgroundTransparency = 1,
				Text = "SELECT TILES TO SWAP",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
			}),

			-- Left side: Your tiles
			e(
				"Frame",
				{
					key = "RackSection",
					Size = UDim2.fromScale(0.55, 0.6),
					Position = UDim2.fromScale(0.05, 0.2),
					BackgroundTransparency = 1,
				},
				(function()
					local children = {
						Layout = e("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							VerticalAlignment = Enum.VerticalAlignment.Center,
							Padding = UDim.new(0.02, 0),
						}),
					}
					for _, tileInfo in ipairs(letters) do
						local id = tileInfo.id
						local letter = tileInfo.letter
						children["Tile_" .. tostring(id)] = e("Frame", {
							Size = UDim2.fromScale(0.12, 0.6),
							BackgroundTransparency = 1,
						}, {
							e(LetterTile, {
								Letter = letter,
								IsSelected = selection[id] == true,
								OnClick = function()
									props.OnToggle(id)
								end,
							}),
						})
					end
					return children
				end)()
			),

			-- Right side: Bag Info
			e("Frame", {
				key = "BagSection",
				Size = UDim2.fromScale(0.3, 0.7),
				Position = UDim2.fromScale(0.65, 0.2),
				BackgroundColor3 = Color3.fromRGB(20, 30, 50),
			}, {
				e("UICorner", { CornerRadius = UDim.new(0.05, 0) }),

				e("TextLabel", {
					key = "Header",
					Size = UDim2.fromScale(1, 0.15),
					BackgroundTransparency = 1,
					Text = "Bag Distribution",
					TextColor3 = Color3.fromRGB(200, 200, 255),
					TextScaled = true,
					FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
				}),

				e(
					"ScrollingFrame",
					{
						key = "Scroll",
						Size = UDim2.fromScale(0.9, 0.8),
						Position = UDim2.fromScale(0.05, 0.18),
						BackgroundTransparency = 1,
						ScrollBarThickness = 2,
						CanvasSize = UDim2.fromScale(0, 1.5),
						ScrollingDirection = Enum.ScrollingDirection.Y,
					},
					(function()
						local children = {
							GridLayout = e("UIGridLayout", {
								CellSize = UDim2.fromScale(0.28, 0.12),
								SortOrder = Enum.SortOrder.Name,
								CellPadding = UDim2.fromScale(0.05, 0.02),
							}),
						}
						for _, info in ipairs(distribution) do
							local letter = info.Letter
							if not letter then
								continue
							end

							children["Item_" .. letter] = e("TextLabel", {
								Text = letter .. ":" .. (info.Count or 0),
								TextColor3 = Color3.new(1, 1, 1),
								BackgroundTransparency = 0.8,
								BackgroundColor3 = Color3.fromRGB(40, 50, 80),
								TextScaled = true,
								FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium),
							}, {
								UICorner = e("UICorner", { CornerRadius = UDim.new(0.2, 0) }),
								UIPadding = e("UIPadding", {
									PaddingTop = UDim.new(0.1, 0),
									PaddingBottom = UDim.new(0.1, 0),
								}),
							})
						end
						return children
					end)()
				),
			}),

			-- Bottom: Actions
			e("Frame", {
				key = "Actions",
				Size = UDim2.fromScale(0.9, 0.15),
				Position = UDim2.fromScale(0.05, 0.82),
				BackgroundTransparency = 1,
			}, {
				e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					Padding = UDim.new(0.02, 0),
				}),

				e(TextButton, {
					Text = "Cancel",
					Variant = "secondary",
					Size = UDim2.fromScale(0.25, 0.8),
					OnClick = props.OnCancel,
				}),

				e(TextButton, {
					Text = "Swap (" .. selectedCount .. ")",
					Variant = "primary",
					Size = UDim2.fromScale(0.35, 0.8),
					Disabled = selectedCount == 0,
					OnClick = props.OnConfirm,
				}),
			}),
		}),
	})
end
