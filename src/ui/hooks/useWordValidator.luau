--[[
	useWordValidator.luau
	
	React hook for validating words against the Scrabble dictionary.
	Provides real-time feedback as the player places tiles.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

-- Load dictionary on client
local ScrabbleDictionary = require(ReplicatedStorage.Shared.Modules.Game.ScrabbleDictionary)
local ScrabbleConfig = require(ReplicatedStorage.Shared.Modules.Game.ScrabbleConfig)

-- Initialize dictionary on load
ScrabbleDictionary:init()

export type WordValidation = {
	word: string,
	isValid: boolean,
	direction: "across" | "down" | "none",
	score: number,
	touchesCenter: boolean,
	error: string?,
	multipliers: { string },
	tileScores: { [number]: number }, -- Maps rackIndex to points contributed
	invalidWords: { string },
}

-- Letter point values
local LETTER_VALUES = {
	A = 1,
	B = 3,
	C = 3,
	D = 2,
	E = 1,
	F = 4,
	G = 2,
	H = 4,
	I = 1,
	J = 8,
	K = 5,
	L = 1,
	M = 3,
	N = 1,
	O = 1,
	P = 3,
	Q = 10,
	R = 1,
	S = 1,
	T = 1,
	U = 1,
	V = 4,
	W = 4,
	X = 8,
	Y = 4,
	Z = 10,
}

-- Check if a word is valid
local function isWordValid(word: string): boolean
	if #word < 2 then
		return false
	end
	return ScrabbleDictionary:isWord(word)
end

-- Calculate basic score for a word (without board multipliers)
local function calculateScore(word: string): number
	local score = 0
	for i = 1, #word do
		local letter = string.upper(string.sub(word, i, i))
		score = score + (LETTER_VALUES[letter] or 0)
	end
	return score
end

-- Check if the board is empty (first move)
-- Board cells can be nil, strings (legacy), or tables with {letter, colors}
local function isBoardEmpty(board: any): boolean
	for row = 1, 15 do
		if board[row] then
			for col = 1, 15 do
				if board[row][col] then
					return false
				end
			end
		end
	end
	return true
end

-- Helper to extract letter from a board cell (handles both string and table formats)
local function extractLetter(cellData: any): string?
	if cellData == nil then
		return nil
	elseif type(cellData) == "string" then
		-- Legacy format: just a letter string
		return cellData
	elseif type(cellData) == "table" and cellData.letter then
		-- New format: {letter: string, colors: {...}}
		return cellData.letter
	end
	return nil
end

-- Helper to extract isBlank from a board cell
local function extractIsBlank(cellData: any): boolean
	if type(cellData) == "table" and cellData.isBlank == true then
		return true
	end
	return false
end

-- Extract word from placed tiles with cross-word validation
local function getWordFromPlacement(
	placedTiles: {
		{
			row: number,
			col: number,
			letter: string,
			rackIndex: number,
			isBlank: boolean?,
		}
	},
	board: any, -- Can contain nil, strings, or tiles with {letter, colors}
	settings: { StarDoublesPoints: boolean? }?,
	blankAssignments: { [string]: string }?
): WordValidation
	if #placedTiles == 0 then
		return {
			word = "",
			isValid = false,
			direction = "none",
			score = 0,
			touchesCenter = false,
			error = nil,
			multipliers = {},
			tileScores = {},
			invalidWords = {},
		}
	end

	-- Determine direction from placed tiles
	local minRow, maxRow = placedTiles[1].row, placedTiles[1].row
	local minCol, maxCol = placedTiles[1].col, placedTiles[1].col

	for _, tile in ipairs(placedTiles) do
		minRow = math.min(minRow, tile.row)
		maxRow = math.max(maxRow, tile.row)
		minCol = math.min(minCol, tile.col)
		maxCol = math.max(maxCol, tile.col)
	end

	local direction: "across" | "down" | "none" = "none"
	if maxRow > minRow and maxCol == minCol then
		direction = "down"
	elseif maxCol > minCol and maxRow == minRow then
		direction = "across"
	elseif #placedTiles == 1 then
		-- Single tile - check which direction forms a word with existing tiles
		local tile = placedTiles[1]
		local hasHorizontalNeighbor = (
			board[tile.row] and (board[tile.row][tile.col - 1] or board[tile.row][tile.col + 1])
		)
		local hasVerticalNeighbor = (board[tile.row - 1] and board[tile.row - 1][tile.col])
			or (board[tile.row + 1] and board[tile.row + 1][tile.col])

		direction = "across"

		if hasHorizontalNeighbor then
			direction = "across"
		elseif hasVerticalNeighbor then
			direction = "down"
		end
	end

	-- Build a lookup for placed tiles
	local placedLookup = {}
	local newTilesMap = {}
	for _, tile in ipairs(placedTiles) do
		placedLookup[tile.row .. "," .. tile.col] = tile
		newTilesMap[tile.row .. "," .. tile.col] = true
	end

	-- Get letter at position (from board or placed tiles)
	local function getLetterAt(row: number, col: number): string?
		local info = placedLookup[row .. "," .. col]
		if info then
			return info.letter
		end
		if board[row] then
			return extractLetter(board[row][col])
		end
		return nil
	end

	-- Check if placed tiles are in a straight line with no invalid gaps
	if #placedTiles > 1 then
		if direction == "none" then
			return {
				word = "",
				isValid = false,
				direction = "none",
				score = 0,
				touchesCenter = false,
				error = "Tiles must be in a straight line",
				multipliers = {},
				tileScores = {},
				invalidWords = {},
			}
		end

		if direction == "across" then
			-- All tiles must be in same row
			for _, tile in ipairs(placedTiles) do
				if tile.row ~= minRow then
					return {
						word = "",
						isValid = false,
						direction = "none",
						score = 0,
						touchesCenter = false,
						error = "Tiles must be in a line",
						multipliers = {},
						tileScores = {},
						invalidWords = {},
					}
				end
			end
			-- Check for gaps - all positions between min and max col must have a letter
			for c = minCol, maxCol do
				if not getLetterAt(minRow, c) then
					return {
						word = "",
						isValid = false,
						direction = "none",
						score = 0,
						touchesCenter = false,
						error = "No gaps allowed",
						multipliers = {},
						tileScores = {},
						invalidWords = {},
					}
				end
			end
		elseif direction == "down" then
			-- All tiles must be in same column
			for _, tile in ipairs(placedTiles) do
				if tile.col ~= minCol then
					return {
						word = "",
						isValid = false,
						direction = "none",
						score = 0,
						touchesCenter = false,
						error = "Tiles must be in a line",
						multipliers = {},
						tileScores = {},
						invalidWords = {},
					}
				end
			end
			-- Check for gaps
			for r = minRow, maxRow do
				if not getLetterAt(r, minCol) then
					return {
						word = "",
						isValid = false,
						direction = "none",
						score = 0,
						touchesCenter = false,
						error = "No gaps allowed",
						multipliers = {},
						tileScores = {},
						invalidWords = {},
					}
				end
			end
		end
	end

	-- Build the main word
	local mainWord = ""
	local mainStartR, mainStartC = minRow, minCol

	if direction == "across" then
		-- Find true start of word (could be before placed tiles)
		local c = minCol
		while c > 1 and getLetterAt(minRow, c - 1) do
			c = c - 1
		end
		mainStartC = c
		mainStartR = minRow

		while c <= 15 and getLetterAt(minRow, c) do
			mainWord = mainWord .. getLetterAt(minRow, c)
			c = c + 1
		end
	elseif direction == "down" then
		-- Find true start of word
		local r = minRow
		while r > 1 and getLetterAt(r - 1, minCol) do
			r = r - 1
		end
		mainStartR = r
		mainStartC = minCol

		while r <= 15 and getLetterAt(r, minCol) do
			mainWord = mainWord .. getLetterAt(r, minCol)
			r = r + 1
		end
	end

	-- Check if any placed tile touches center (8,8)
	local touchesCenter = false
	for _, tile in ipairs(placedTiles) do
		if tile.row == 8 and tile.col == 8 then
			touchesCenter = true
			break
		end
	end

	-- Track invalid words collected
	local invalidWords = {}
	local function addInvalid(w)
		if not table.find(invalidWords, w) then
			table.insert(invalidWords, w)
		end
	end

	-- On first move, word must touch center
	local boardEmpty = isBoardEmpty(board)
	if boardEmpty and not touchesCenter then
		addInvalid(mainWord)
	end

	-- Check adjacency: if not first move, must connect to existing tiles
	if not boardEmpty then
		local touchesExisting = false
		for _, tile in ipairs(placedTiles) do
			local neighbors = {
				{ tile.row - 1, tile.col },
				{ tile.row + 1, tile.col },
				{ tile.row, tile.col - 1 },
				{ tile.row, tile.col + 1 },
			}
			for _, pos in ipairs(neighbors) do
				local r, c = pos[1], pos[2]
				if r >= 1 and r <= 15 and c >= 1 and c <= 15 then
					if board[r] and board[r][c] then
						touchesExisting = true
						break
					end
				end
			end
			if touchesExisting then
				break
			end
		end

		if not touchesExisting then
			addInvalid(mainWord)
		end
	end

	-- Validate main word
	if not isWordValid(mainWord) then
		addInvalid(mainWord)
	end

	-- Track active multipliers for display
	local activeMultipliers = {}
	local tileScores = {} -- Track per-tile contributions

	-- Scoring helper
	local function calculateSegmentScore(word, startR, startC, dir)
		local segmentScore = 0
		local wordMult = 1
		local placedInSegment = {} -- Track rackIndices of placed tiles in this word

		for i = 1, #word do
			local r, c = startR, startC
			if dir == "across" then
				c = startC + i - 1
			else
				r = startR + i - 1
			end

			local letter = string.sub(word, i, i)

			-- Determine strictly if this tile is a blank (0 points)
			local isBlank = false
			local placedInfo = placedLookup[r .. "," .. c]

			if placedInfo then
				-- Check pending blank assignments for placed tiles
				local posKey = r .. "," .. c
				if blankAssignments and blankAssignments[posKey] then
					isBlank = true
				end
			else
				-- Check existing board tiles
				if board[r] and extractIsBlank(board[r][c]) then
					isBlank = true
				end
			end

			local val = if isBlank then 0 else (LETTER_VALUES[letter] or 0)
			local contribution = val

			if placedInfo then
				-- Special handling for center star based on settings
				if r == 8 and c == 8 then
					local isDoubling = not (settings and settings.StarDoublesPoints == false)
					local mult = if isDoubling then 2 else 1
					wordMult *= mult
					contribution = val
					if isDoubling then
						table.insert(activeMultipliers, "CENTER")
					end
				else
					local type = ScrabbleConfig.SPECIAL_POSITIONS[r .. "," .. c]
					local m = type and ScrabbleConfig.MULTIPLIERS[type]
					local lMult = m and m.letter or 1
					local wMult = m and m.word or 1

					contribution = val * lMult
					wordMult = wordMult * wMult

					if type then
						table.insert(activeMultipliers, type)
					end
				end

				table.insert(placedInSegment, placedInfo.rackIndex)
			end
			segmentScore += contribution
		end

		local finalSegmentScore = segmentScore * wordMult

		-- Distribute the TOTAL score of this word among the new tiles that formed it
		-- This ensures that points from existing tiles (stacking) are visualized
		local count = #placedInSegment
		if count > 0 then
			local baseAmount = math.floor(finalSegmentScore / count)
			local remainder = finalSegmentScore % count

			for i, rackIndex in ipairs(placedInSegment) do
				local amount = baseAmount
				if i == count then
					amount += remainder
				end
				tileScores[rackIndex] = (tileScores[rackIndex] or 0) + amount
			end
		end

		return finalSegmentScore
	end

	-- Calculate score for main word
	local totalScore = calculateSegmentScore(mainWord, mainStartR, mainStartC, direction)

	-- Check all cross-words (perpendicular words formed by placed tiles)
	local crossDir = if direction == "across" then "down" else "across"

	for _, tile in ipairs(placedTiles) do
		-- Only check cross words
		local cwStartR, cwStartC, cwLen = tile.row, tile.col, 0

		if crossDir == "across" then
			local c = tile.col
			while c > 1 and getLetterAt(tile.row, c - 1) do
				c = c - 1
			end
			cwStartC = c
			cwStartR = tile.row
			local crossWord = ""
			while c <= 15 and getLetterAt(tile.row, c) do
				crossWord = crossWord .. getLetterAt(tile.row, c)
				c = c + 1
			end
			cwLen = #crossWord

			if cwLen > 1 then
				if not isWordValid(crossWord) then
					addInvalid(crossWord)
				else
					totalScore = totalScore + calculateSegmentScore(crossWord, cwStartR, cwStartC, crossDir)
				end
			end
		else -- down
			local r = tile.row
			while r > 1 and getLetterAt(r - 1, tile.col) do
				r = r - 1
			end
			cwStartR = r
			cwStartC = tile.col
			local crossWord = ""
			while r <= 15 and getLetterAt(r, tile.col) do
				crossWord = crossWord .. getLetterAt(r, tile.col)
				r = r + 1
			end
			cwLen = #crossWord

			if cwLen > 1 then
				if not isWordValid(crossWord) then
					addInvalid(crossWord)
				else
					totalScore = totalScore + calculateSegmentScore(crossWord, cwStartR, cwStartC, crossDir)
				end
			end
		end
	end

	if #invalidWords > 0 then
		local errorMsg = nil
		if boardEmpty and not touchesCenter then
			errorMsg = "First word must start on the ★"
		elseif not boardEmpty then
			-- adjacency check
			local touchesExisting = false
			for _, tile in ipairs(placedTiles) do
				local neighbors = {
					{ tile.row - 1, tile.col },
					{ tile.row + 1, tile.col },
					{ tile.row, tile.col - 1 },
					{ tile.row, tile.col + 1 },
				}
				for _, pos in ipairs(neighbors) do
					local r, c = pos[1], pos[2]
					if r >= 1 and r <= 15 and c >= 1 and c <= 15 then
						if board[r] and board[r][c] then
							touchesExisting = true
							break
						end
					end
				end
				if touchesExisting then
					break
				end
			end
			if not touchesExisting then
				errorMsg = "Must connect to existing words"
			end
		end

		return {
			word = mainWord,
			isValid = false,
			direction = direction,
			score = 0,
			touchesCenter = touchesCenter,
			error = errorMsg,
			multipliers = {},
			tileScores = {},
			invalidWords = invalidWords,
		}
	end

	return {
		word = mainWord,
		isValid = true,
		direction = direction,
		score = totalScore,
		touchesCenter = touchesCenter,
		error = nil,
		multipliers = activeMultipliers,
		tileScores = tileScores,
		invalidWords = {},
	}
end

-- React hook
local function useWordValidator(
	placedTiles: { { row: number, col: number, letter: string, rackIndex: number } },
	board: any, -- Can contain nil, strings, or tiles with {letter, colors}
	settings: { StarDoublesPoints: boolean? }?,
	blankAssignments: { [string]: string }?
): WordValidation
	local validation, setValidation = React.useState({
		word = "",
		isValid = false,
		direction = "none" :: "across" | "down" | "none",
		score = 0,
		touchesCenter = false,
		error = nil :: string?,
		multipliers = {} :: { string },
		tileScores = {} :: { [number]: number },
		invalidWords = {} :: { string },
	})

	React.useEffect(function()
		local result = getWordFromPlacement(placedTiles, board, settings, blankAssignments)
		setValidation(result)
	end, { placedTiles, board, settings, blankAssignments } :: { any })

	return validation
end

return {
	useWordValidator = useWordValidator,
	isWordValid = isWordValid,
	calculateScore = calculateScore,
}
