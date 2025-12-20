--[[
	GameControls.luau
	
	Control buttons for the game: Submit word, Pass turn, Exchange tiles.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)

local e = React.createElement

export type GameControlsProps = {
	IsMyTurn: boolean,
	CanSubmit: boolean, -- Has a valid word placed
	IsExchangeMode: boolean?, -- In exchange tile selection mode
	ExchangeCount: number?, -- Number of tiles selected for exchange
	OnSubmit: (() -> ())?,
	OnPass: (() -> ())?,
	OnExchange: (() -> ())?,
	OnCancelExchange: (() -> ())?,
	OnClear: (() -> ())?,
	CanPass: boolean?,
}

return function(props: GameControlsProps)
	local isMyTurn = props.IsMyTurn
	local canSubmit = props.CanSubmit
	local isExchangeMode = props.IsExchangeMode
	local exchangeCount = props.ExchangeCount or 0
	
	-- Exchange mode shows different buttons
	if isExchangeMode then
		return e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			UIListLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0.02, 0),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			UIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.3, 0),
			}),
			
			Instruction = e("Frame", {
				Size = UDim2.fromScale(0.35, 0.8),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, {
				Label = e("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "Click tiles to exchange (" .. exchangeCount .. " selected)",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					FontFace = Font.new(
						"rbxassetid://11702779517",
						Enum.FontWeight.Medium,
						Enum.FontStyle.Italic
					),
				}),
			}),
			
			CancelButton = e("Frame", {
				Size = UDim2.fromScale(0.25, 0.8),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				Button = e(TextButton, {
					Text = "Cancel",
					Variant = "secondary",
					Size = UDim2.fromScale(1, 1),
					OnClick = props.OnCancelExchange,
				}),
			}),
			
			ConfirmButton = e("Frame", {
				Size = UDim2.fromScale(0.3, 0.8),
				BackgroundTransparency = 1,
				LayoutOrder = 3,
			}, {
				Button = e(TextButton, {
					Text = "Confirm Exchange",
					Variant = "primary",
					Size = UDim2.fromScale(1, 1),
					Disabled = exchangeCount == 0,
					OnClick = props.OnExchange,
				}),
			}),
		})
	end
	
	-- Normal mode
	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		UIListLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0.02, 0),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),

		UIPadding = e("UIPadding", {
			PaddingBottom = UDim.new(0.3, 0),
		}),
		
		ClearButton = e("Frame", {
			Size = UDim2.fromScale(0.22, 0.8),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			Button = e(TextButton, {
				Text = "Clear",
				Variant = "secondary",
				Size = UDim2.fromScale(1, 1),
				-- Always allow clearing strategic placements
				OnClick = props.OnClear,
			}),
		}),
		
		ExchangeButton = e("Frame", {
			Size = UDim2.fromScale(0.22, 0.8),
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}, {
			Button = e(TextButton, {
				Text = "Exchange",
				Variant = "secondary",
				Size = UDim2.fromScale(1, 1),
				Disabled = not isMyTurn,
				OnClick = props.OnExchange,
			}),
		}),
		
		PassButton = e("Frame", {
			Size = UDim2.fromScale(0.22, 0.8),
			BackgroundTransparency = 1,
			LayoutOrder = 3,
		}, {
			Button = e(TextButton, {
				Text = "Pass",
				Variant = "secondary",
				Size = UDim2.fromScale(1, 1),
				Disabled = not isMyTurn or props.CanPass == false,
				OnClick = props.OnPass,
			}),
		}),
		
		SubmitButton = e("Frame", {
			Size = UDim2.fromScale(0.3, 0.8),
			BackgroundTransparency = 1,
			LayoutOrder = 4,
		}, {
			Button = e(TextButton, {
				Text = "Submit",
				Variant = "primary",
				Size = UDim2.fromScale(1, 1),
				Disabled = not isMyTurn or not canSubmit,
				OnClick = props.OnSubmit,
			}),
		}),
	})
end

