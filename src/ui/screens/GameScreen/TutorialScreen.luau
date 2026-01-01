--[[
	TutorialScreen.luau
	
	First-time tutorial that teaches players how to play Scrabble.
	Players must manually navigate through all slides before they can exit.
	Features actual game UI components as visual examples.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local SoundUtils = require(ReplicatedStorage.Shared.Modules.Core.SoundUtils)
local TextButton = require(ReplicatedStorage.UI.components.buttons.TextButton)
local StyledPanel = require(ReplicatedStorage.UI.components.frames.StyledPanel)
local TransitionFrameModule = require(ReplicatedStorage.UI.components.frames.TransitionFrame)
local TransitionFrame = TransitionFrameModule.TransitionFrame
local LetterTile = require(ReplicatedStorage.UI.components.game.LetterTile)

local e = React.createElement

-- Configuration
local TUTORIAL_CONFIG = {
	TOTAL_SLIDES = 4,
}

-- Board cell colors matching the actual game
local BONUS_COLORS = {
	DL = Color3.fromRGB(135, 206, 235), -- Light blue - Double Letter
	TL = Color3.fromRGB(70, 130, 180), -- Steel blue - Triple Letter
	DW = Color3.fromRGB(255, 182, 193), -- Pink - Double Word
	TW = Color3.fromRGB(255, 99, 71), -- Tomato - Triple Word
	CENTER = Color3.fromRGB(255, 215, 0), -- Gold - Center star
	EMPTY = Color3.fromRGB(45, 65, 95), -- Dark blue - Empty
}

-- Mini board cell component for tutorial (with aspect ratio)
local function MiniCell(props: { bonus: string?, label: string? })
	local bonus = props.bonus or "EMPTY"
	local color = BONUS_COLORS[bonus] or BONUS_COLORS.EMPTY
	
	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color,
	}, {
		UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
			AspectRatio = 1,
		}),
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0.15, 0),
		}),
		UIStroke = e("UIStroke", {
			Color = Color3.new(1, 1, 1),
			Thickness = 1,
			Transparency = 0.5,
		}),
		Label = props.label and e("TextLabel", {
			Size = UDim2.fromScale(0.85, 0.85),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Text = props.label,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
		}) or nil,
	})
end

-- Wrapper for LetterTile to set proper size
local function TutorialTile(props: { letter: string, index: number? })
	return e("Frame", {
		Size = UDim2.fromOffset(50, 50),
		BackgroundTransparency = 1,
	}, {
		Tile = e(LetterTile, {
			Letter = props.letter,
			Index = props.index or 1,
			IsSelected = false,
			IsDisabled = false,
			IsDragging = false,
			NoPop = true,
			Active = false,
		}),
	})
end

-- SLIDE 1: The Board - Explains the game board and bonus squares
local function BoardVisual()
	-- Create 5x5 grid cells
	local cells = {}
	local GRID = {
		{ "TW", "", "DL", "", "TW" },
		{ "", "DW", "", "DW", "" },
		{ "DL", "", "CENTER", "", "TL" },
		{ "", "DW", "", "DW", "" },
		{ "TW", "", "TL", "", "TW" },
	}
	local LABELS = { TW = "3W", TL = "3L", DW = "2W", DL = "2L", CENTER = "★" }
	
	for row = 1, 5 do
		for col = 1, 5 do
			local cellType = GRID[row][col]
			local idx = (row - 1) * 5 + col
			cells["C" .. idx] = e("Frame", {
				Size = UDim2.fromScale(0.19, 0.19),
				BackgroundTransparency = 1,
				LayoutOrder = idx,
			}, {
				Cell = e(MiniCell, {
					bonus = if cellType == "" then "EMPTY" else cellType,
					label = LABELS[cellType],
				}),
			})
		end
	end
	
	cells.UIGridLayout = e("UIGridLayout", {
		CellSize = UDim2.fromScale(0.19, 0.19),
		CellPadding = UDim2.fromScale(0.01, 0.01),
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		ExplanationHeader = e("TextLabel", {
			Size = UDim2.fromScale(0.95, 0.12),
			Position = UDim2.fromScale(0.5, 0.02),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Text = "Screbblo is played on a 15×15 board with special bonus squares:",
			TextColor3 = Color3.fromRGB(220, 235, 255),
			TextScaled = true,
			TextWrapped = true,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium),
		}),

		BoardContainer = e("Frame", {
			Size = UDim2.fromScale(0.38, 0.6),
			Position = UDim2.fromScale(0.05, 0.5),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
		}, {
			UIAspectRatioConstraint = e("UIAspectRatioConstraint", { AspectRatio = 1 }),
			Grid = e("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			}, cells),
		}),
		
		Legend = e("Frame", {
			Size = UDim2.fromScale(0.5, 0.7),
			Position = UDim2.fromScale(0.95, 0.5),
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
		}, {
			UIListLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0.02, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			L1 = e("Frame", { Size = UDim2.new(1, 0, 0.16, 0), BackgroundTransparency = 1, LayoutOrder = 1 }, {
				Box = e("Frame", { Size = UDim2.fromScale(0.08, 1), BackgroundColor3 = BONUS_COLORS.DL }, {
					UIAspectRatioConstraint = e("UIAspectRatioConstraint", { AspectRatio = 1 }),
					UICorner = e("UICorner", { CornerRadius = UDim.new(0.2, 0) }),
				}),
				Text = e("TextLabel", { Size = UDim2.new(0.9, 0, 1, 0), Position = UDim2.fromScale(0.1, 0), BackgroundTransparency = 1, Text = "2L = Double the letter's points", TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, TextScaled = true, FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium) }),
			}),
			L2 = e("Frame", { Size = UDim2.new(1, 0, 0.16, 0), BackgroundTransparency = 1, LayoutOrder = 2 }, {
				Box = e("Frame", { Size = UDim2.fromScale(0.08, 1), BackgroundColor3 = BONUS_COLORS.TL }, {
					UIAspectRatioConstraint = e("UIAspectRatioConstraint", { AspectRatio = 1 }),
					UICorner = e("UICorner", { CornerRadius = UDim.new(0.2, 0) }),
				}),
				Text = e("TextLabel", { Size = UDim2.new(0.9, 0, 1, 0), Position = UDim2.fromScale(0.1, 0), BackgroundTransparency = 1, Text = "3L = Triple the letter's points", TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, TextScaled = true, FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium) }),
			}),
			L3 = e("Frame", { Size = UDim2.new(1, 0, 0.16, 0), BackgroundTransparency = 1, LayoutOrder = 3 }, {
				Box = e("Frame", { Size = UDim2.fromScale(0.08, 1), BackgroundColor3 = BONUS_COLORS.DW }, {
					UIAspectRatioConstraint = e("UIAspectRatioConstraint", { AspectRatio = 1 }),
					UICorner = e("UICorner", { CornerRadius = UDim.new(0.2, 0) }),
				}),
				Text = e("TextLabel", { Size = UDim2.new(0.9, 0, 1, 0), Position = UDim2.fromScale(0.1, 0), BackgroundTransparency = 1, Text = "2W = Double your ENTIRE word", TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, TextScaled = true, FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium) }),
			}),
			L4 = e("Frame", { Size = UDim2.new(1, 0, 0.16, 0), BackgroundTransparency = 1, LayoutOrder = 4 }, {
				Box = e("Frame", { Size = UDim2.fromScale(0.08, 1), BackgroundColor3 = BONUS_COLORS.TW }, {
					UIAspectRatioConstraint = e("UIAspectRatioConstraint", { AspectRatio = 1 }),
					UICorner = e("UICorner", { CornerRadius = UDim.new(0.2, 0) }),
				}),
				Text = e("TextLabel", { Size = UDim2.new(0.9, 0, 1, 0), Position = UDim2.fromScale(0.1, 0), BackgroundTransparency = 1, Text = "3W = Triple your ENTIRE word!", TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, TextScaled = true, FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium) }),
			}),
			L5 = e("Frame", { Size = UDim2.new(1, 0, 0.16, 0), BackgroundTransparency = 1, LayoutOrder = 5 }, {
				Box = e("Frame", { Size = UDim2.fromScale(0.08, 1), BackgroundColor3 = BONUS_COLORS.CENTER }, {
					UIAspectRatioConstraint = e("UIAspectRatioConstraint", { AspectRatio = 1 }),
					UICorner = e("UICorner", { CornerRadius = UDim.new(0.2, 0) }),
				}),
				Text = e("TextLabel", { Size = UDim2.new(0.9, 0, 1, 0), Position = UDim2.fromScale(0.1, 0), BackgroundTransparency = 1, Text = "★ = Start here! (counts as 2W)", TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, TextScaled = true, FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium) }),
			}),
		}),
		
		-- Bottom tip
		BottomTip = e("TextLabel", {
			Size = UDim2.fromScale(0.9, 0.1),
			Position = UDim2.fromScale(0.5, 0.92),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Text = "💡 The first word must cover the center ★ star!",
			TextColor3 = Color3.fromRGB(255, 220, 100),
			TextScaled = true,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
		}),
	})
end

-- SLIDE 2: Your Tiles - Explains how to place tiles
local function TilesVisual()
	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		-- Step 1 explanation
		Step1 = e("Frame", {
			Size = UDim2.fromScale(0.45, 0.35),
			Position = UDim2.fromScale(0.25, 0.2),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
		}, {
			StepLabel = e("TextLabel", {
				Size = UDim2.new(1, 0, 0.3, 0),
				BackgroundTransparency = 1,
				Text = "1️⃣ You have 7 tiles in your rack:",
				TextColor3 = Color3.fromRGB(150, 220, 255),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Center,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
			}),
			Rack = e("Frame", {
				Size = UDim2.fromScale(0.95, 0.55),
				Position = UDim2.fromScale(0.5, 0.7),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(139, 90, 43),
			}, {
				UICorner = e("UICorner", { CornerRadius = UDim.new(0.15, 0) }),
				UIStroke = e("UIStroke", { Color = Color3.fromRGB(101, 67, 33), Thickness = 3 }),
				Tiles = e("Frame", {
					Size = UDim2.fromScale(0.95, 0.8),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
				}, {
					UIListLayout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						Padding = UDim.new(0, 4),
					}),
					T1 = e(TutorialTile, { letter = "S", index = 1 }),
					T2 = e(TutorialTile, { letter = "C", index = 2 }),
					T3 = e(TutorialTile, { letter = "R", index = 3 }),
					T4 = e(TutorialTile, { letter = "A", index = 4 }),
					T5 = e(TutorialTile, { letter = "B", index = 5 }),
					T6 = e(TutorialTile, { letter = "L", index = 6 }),
					T7 = e(TutorialTile, { letter = "E", index = 7 }),
				}),
			}),
		}),
		
		-- Arrow
		Arrow = e("TextLabel", {
			Size = UDim2.fromScale(0.1, 0.15),
			Position = UDim2.fromScale(0.5, 0.2),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Text = "➡️",
			TextScaled = true,
		}),
		
		-- Step 2 explanation
		Step2 = e("Frame", {
			Size = UDim2.fromScale(0.45, 0.35),
			Position = UDim2.fromScale(0.75, 0.2),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
		}, {
			StepLabel = e("TextLabel", {
				Size = UDim2.new(1, 0, 0.3, 0),
				BackgroundTransparency = 1,
				Text = "2️⃣ Drag tiles to spell a word:",
				TextColor3 = Color3.fromRGB(150, 255, 180),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Center,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
			}),
			Word = e("Frame", {
				Size = UDim2.fromScale(0.9, 0.55),
				Position = UDim2.fromScale(0.5, 0.7),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
			}, {
				UIListLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 4),
				}),
				T1 = e(TutorialTile, { letter = "C", index = 1 }),
				T2 = e(TutorialTile, { letter = "A", index = 2 }),
				T3 = e(TutorialTile, { letter = "R", index = 3 }),
				T4 = e(TutorialTile, { letter = "S", index = 4 }),
			}),
		}),
		
		-- Rules section at bottom
		Rules = e("Frame", {
			Size = UDim2.fromScale(0.95, 0.45),
			Position = UDim2.fromScale(0.5, 0.7),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
		}, {
			UIListLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				Padding = UDim.new(0, 8),
			}),
			Rule1 = e("TextLabel", {
				Size = UDim2.new(1, 0, 0.25, 0),
				BackgroundTransparency = 1,
				Text = "✓ Words must go left-to-right or top-to-bottom",
				TextColor3 = Color3.fromRGB(180, 220, 255),
				TextScaled = true,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium),
			}),
			Rule2 = e("TextLabel", {
				Size = UDim2.new(1, 0, 0.25, 0),
				BackgroundTransparency = 1,
				Text = "✓ After the first turn, you must connect to existing tiles",
				TextColor3 = Color3.fromRGB(180, 220, 255),
				TextScaled = true,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium),
			}),
			Rule3 = e("TextLabel", {
				Size = UDim2.new(1, 0, 0.25, 0),
				BackgroundTransparency = 1,
				Text = "✓ Press PLAY when you're happy with your word!",
				TextColor3 = Color3.fromRGB(150, 255, 150),
				TextScaled = true,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
			}),
		}),
	})
end

-- SLIDE 3: Scoring - Explains letter point values
local function ScoringVisual()
	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		-- Explanation header
		Header = e("TextLabel", {
			Size = UDim2.fromScale(0.95, 0.12),
			Position = UDim2.fromScale(0.5, 0.02),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Text = "Each tile has a point value shown in the corner:",
			TextColor3 = Color3.fromRGB(220, 235, 255),
			TextScaled = true,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium),
		}),
		
		-- Common letters section
		CommonSection = e("Frame", {
			Size = UDim2.fromScale(0.9, 0.3),
			Position = UDim2.fromScale(0.5, 0.25),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
		}, {
			Label = e("TextLabel", {
				Size = UDim2.fromScale(1, 0.3),
				BackgroundTransparency = 1,
				Text = "Common letters are worth 1-2 points:",
				TextColor3 = Color3.fromRGB(150, 255, 150),
				TextScaled = true,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
			}),
			Tiles = e("Frame", {
				Size = UDim2.fromScale(1, 0.65),
				Position = UDim2.fromScale(0, 0.35),
				BackgroundTransparency = 1,
			}, {
				UIListLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 12),
				}),
				T1 = e(TutorialTile, { letter = "E", index = 1 }),
				T2 = e(TutorialTile, { letter = "A", index = 2 }),
				T3 = e(TutorialTile, { letter = "I", index = 3 }),
				T4 = e(TutorialTile, { letter = "O", index = 4 }),
				T5 = e(TutorialTile, { letter = "N", index = 5 }),
				T6 = e(TutorialTile, { letter = "R", index = 6 }),
				T7 = e(TutorialTile, { letter = "T", index = 7 }),
			}),
		}),
		
		-- Rare letters section
		RareSection = e("Frame", {
			Size = UDim2.fromScale(0.9, 0.3),
			Position = UDim2.fromScale(0.5, 0.58),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
		}, {
			Label = e("TextLabel", {
				Size = UDim2.fromScale(1, 0.3),
				BackgroundTransparency = 1,
				Text = "Rare letters are worth 8-10 points each!",
				TextColor3 = Color3.fromRGB(255, 200, 100),
				TextScaled = true,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
			}),
			Tiles = e("Frame", {
				Size = UDim2.fromScale(1, 0.65),
				Position = UDim2.fromScale(0, 0.35),
				BackgroundTransparency = 1,
			}, {
				UIListLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 12),
				}),
				T1 = e(TutorialTile, { letter = "Q", index = 1 }),
				T2 = e(TutorialTile, { letter = "Z", index = 2 }),
				T3 = e(TutorialTile, { letter = "X", index = 3 }),
				T4 = e(TutorialTile, { letter = "J", index = 4 }),
				T5 = e(TutorialTile, { letter = "K", index = 5 }),
			}),
		}),
		
		-- Strategy tip
		Tip = e("TextLabel", {
			Size = UDim2.fromScale(0.9, 0.12),
			Position = UDim2.fromScale(0.5, 0.88),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Text = "💡 Combine rare letters with bonus squares for MEGA points!",
			TextColor3 = Color3.fromRGB(255, 220, 100),
			TextScaled = true,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
		}),
	})
end

-- SLIDE 4: Ready to Play
local function ReadyVisual()
	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		-- Trophy/celebration icon
		Icon = e("TextLabel", {
			Size = UDim2.fromScale(0.2, 0.25),
			Position = UDim2.fromScale(0.5, 0.15),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Text = "🏆",
			TextScaled = true,
		}),
		
		-- Quick tips header
		Header = e("TextLabel", {
			Size = UDim2.fromScale(0.9, 0.1),
			Position = UDim2.fromScale(0.5, 0.32),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Text = "Quick Tips to Win:",
			TextColor3 = Color3.fromRGB(68, 210, 253),
			TextScaled = true,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy),
		}),
		
		-- Tips list
		Tips = e("Frame", {
			Size = UDim2.fromScale(0.85, 0.45),
			Position = UDim2.fromScale(0.5, 0.62),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
		}, {
			UIListLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 10),
			}),
			Tip1 = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundTransparency = 1,
				Text = "✓ Plan ahead - aim for bonus squares!",
				TextColor3 = Color3.fromRGB(150, 255, 150),
				TextScaled = true,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium),
			}),
			Tip2 = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundTransparency = 1,
				Text = "✓ Save rare letters (Q, Z, X, J) for multipliers",
				TextColor3 = Color3.fromRGB(255, 220, 150),
				TextScaled = true,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium),
			}),
			Tip3 = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundTransparency = 1,
				Text = "✓ Build on other players' words for combos",
				TextColor3 = Color3.fromRGB(150, 200, 255),
				TextScaled = true,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium),
			}),
			Tip4 = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundTransparency = 1,
				Text = "✓ Watch the timer - don't run out of time!",
				TextColor3 = Color3.fromRGB(255, 180, 200),
				TextScaled = true,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium),
			}),
		}),
		
		-- Final message
		FinalMessage = e("TextLabel", {
			Size = UDim2.fromScale(0.9, 0.08),
			Position = UDim2.fromScale(0.5, 0.92),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Text = "You're ready! Good luck and have fun! 🎉",
			TextColor3 = Color3.fromRGB(255, 255, 200),
			TextScaled = true,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Bold),
		}),
	})
end

-- Tutorial slide content definitions
local SLIDE_CONTENT = {
	{
		title = "THE BOARD",
		subtitle = "Learn about bonus squares",
		visual = BoardVisual,
	},
	{
		title = "HOW TO PLAY",
		subtitle = "Drag tiles to spell words",
		visual = TilesVisual,
	},
	{
		title = "SCORING",
		subtitle = "Each tile has a point value",
		visual = ScoringVisual,
	},
	{
		title = "READY TO PLAY!",
		subtitle = "You've got this!",
		visual = ReadyVisual,
	},
}

-- Individual slide component
local function TutorialSlide(props: { slideData: typeof(SLIDE_CONTENT[1]), slideIndex: number })
	local slideData = props.slideData

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		-- Visual area (main portion)
		VisualArea = e("Frame", {
			Size = UDim2.fromScale(1, 0.68),
			Position = UDim2.fromScale(0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
		}, {
			Visual = slideData.visual and e(slideData.visual) or nil,
		}),

		-- Title
		Title = e("TextLabel", {
			Size = UDim2.fromScale(0.9, 0.08),
			Position = UDim2.fromScale(0.5, 0.70),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Text = slideData.title,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
		}, {
			UIStroke = e("UIStroke", {
				Color = Color3.new(0, 0, 0),
				Thickness = 2,
				Transparency = 0.5,
			}),
		}),

		-- Subtitle
		Subtitle = e("TextLabel", {
			Size = UDim2.fromScale(0.85, 0.05),
			Position = UDim2.fromScale(0.5, 0.79),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Text = slideData.subtitle,
			TextColor3 = Color3.fromRGB(200, 220, 255),
			TextScaled = true,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium, Enum.FontStyle.Italic),
		}),
	})
end

-- Slide indicator dots
local function SlideIndicators(props: { currentSlide: number, totalSlides: number })
	local dots = {}

	for i = 1, props.totalSlides do
		local isActive = i == props.currentSlide
		local isPast = i < props.currentSlide
		dots["Dot_" .. i] = e("Frame", {
			Size = UDim2.fromOffset(isActive and 14 or 10, isActive and 14 or 10),
			BackgroundColor3 = if isActive
				then Color3.fromRGB(68, 210, 253)
				elseif isPast then Color3.fromRGB(100, 180, 220)
				else Color3.fromRGB(60, 70, 90),
			LayoutOrder = i,
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0.5, 0),
			}),
		})
	end

	dots.UIListLayout = e("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	return e("Frame", {
		Size = UDim2.new(0.5, 0, 0, 24),
		Position = UDim2.fromScale(0.5, 0.88),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = 12,
	}, dots)
end

export type TutorialScreenProps = {
	OnTutorialComplete: (() -> ())?,
}

return function(props: TutorialScreenProps)
	local currentSlide, setCurrentSlide = React.useState(1)
	local slideDirection, setSlideDirection = React.useState("Right")
	local hasReachedEnd, setHasReachedEnd = React.useState(false)

	local totalSlides = TUTORIAL_CONFIG.TOTAL_SLIDES

	React.useEffect(function()
		if currentSlide == totalSlides then
			setHasReachedEnd(true)
		end
	end, { currentSlide })

	local function goToNextSlide()
		if currentSlide < totalSlides then
			SoundUtils.playWoosh()
			setSlideDirection("Right")
			setCurrentSlide(currentSlide + 1)
		end
	end

	local function goToPrevSlide()
		if currentSlide > 1 then
			SoundUtils.playWoosh()
			setSlideDirection("Left")
			setCurrentSlide(currentSlide - 1)
		end
	end

	local function handleComplete()
		SoundUtils.playButtonClick()
		if props.OnTutorialComplete then
			props.OnTutorialComplete()
		end
	end

	local slideContent = e(TutorialSlide, {
		slideData = SLIDE_CONTENT[currentSlide],
		slideIndex = currentSlide,
	})

	local isFirstSlide = currentSlide == 1
	local isLastSlide = currentSlide == totalSlides

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 10,
	}, {
		Panel = e(StyledPanel, {
			Size = UDim2.fromScale(0.75, 0.85),
			Position = UDim2.fromScale(0.5, 0.48),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = 10,
			Children = {
				Header = e("TextLabel", {
					Size = UDim2.fromScale(0.9, 0.05),
					Position = UDim2.fromScale(0.5, 0.01),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundTransparency = 1,
					Text = "HOW TO PLAY",
					TextColor3 = Color3.fromRGB(68, 210, 253),
					TextScaled = true,
					FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
					ZIndex = 11,
				}),

				SlideContainer = e("Frame", {
					Size = UDim2.fromScale(0.95, 0.76),
					Position = UDim2.fromScale(0.5, 0.07),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					ZIndex = 11,
				}, {
					SlideTransition = e(TransitionFrame, {
						TransitionKey = currentSlide,
						Duration = 0.4,
						Type = "Slide",
						Direction = slideDirection,
						Silent = true,
					}, slideContent),
				}),

				Indicators = e(SlideIndicators, {
					currentSlide = currentSlide,
					totalSlides = totalSlides,
				}),

				NavButtons = e("Frame", {
					Size = UDim2.fromScale(0.9, 0.07),
					Position = UDim2.fromScale(0.5, 0.95),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					ZIndex = 12,
				}, {
					UIListLayout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						Padding = UDim.new(0.03, 0),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),

					PrevButton = e("Frame", {
						Size = UDim2.fromScale(0.25, 1),
						BackgroundTransparency = 1,
						LayoutOrder = 1,
					}, {
						Button = e(TextButton, {
							Text = "◀  BACK",
							Variant = "secondary",
							Size = UDim2.fromScale(1, 1),
							Disabled = isFirstSlide,
							OnClick = goToPrevSlide,
						}),
					}),

					NextButton = e("Frame", {
						Size = UDim2.fromScale(0.30, 1),
						BackgroundTransparency = 1,
						LayoutOrder = 2,
					}, {
						Button = e(TextButton, {
							Text = if isLastSlide then "✓  LET'S PLAY!" else "NEXT  ▶",
							Variant = "primary",
							Size = UDim2.fromScale(1, 1),
							Disabled = isLastSlide and not hasReachedEnd,
							OnClick = if isLastSlide then handleComplete else goToNextSlide,
						}),
					}),
				}),
			},
		}),

		SlideCounter = e("TextLabel", {
			Size = UDim2.fromScale(0.15, 0.04),
			Position = UDim2.fromScale(0.5, 0.96),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Text = string.format("%d / %d", currentSlide, totalSlides),
			TextColor3 = Color3.fromRGB(150, 160, 180),
			TextScaled = true,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium),
			ZIndex = 20,
		}),
	})
end
