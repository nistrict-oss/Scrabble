--[[
	ScrabbleConfig.luau

	Lightweight configuration for a UI-only Scrabble experience.
	Contains letter distributions, board dimensions, and helper
	functions to build a tile bag.
]]

local ScrabbleConfig = {}

ScrabbleConfig.BOARD_SIZE = 15
ScrabbleConfig.RACK_SIZE = 7

-- Standard English letter distribution and values (classic Scrabble).
ScrabbleConfig.LETTERS = {
	{ letter = "A", count = 9, value = 1 },
	{ letter = "B", count = 2, value = 3 },
	{ letter = "C", count = 2, value = 3 },
	{ letter = "D", count = 4, value = 2 },
	{ letter = "E", count = 12, value = 1 },
	{ letter = "F", count = 2, value = 4 },
	{ letter = "G", count = 3, value = 2 },
	{ letter = "H", count = 2, value = 4 },
	{ letter = "I", count = 9, value = 1 },
	{ letter = "J", count = 1, value = 8 },
	{ letter = "K", count = 1, value = 5 },
	{ letter = "L", count = 4, value = 1 },
	{ letter = "M", count = 2, value = 3 },
	{ letter = "N", count = 6, value = 1 },
	{ letter = "O", count = 8, value = 1 },
	{ letter = "P", count = 2, value = 3 },
	{ letter = "Q", count = 1, value = 10 },
	{ letter = "R", count = 6, value = 1 },
	{ letter = "S", count = 4, value = 1 },
	{ letter = "T", count = 6, value = 1 },
	{ letter = "U", count = 4, value = 1 },
	{ letter = "V", count = 2, value = 4 },
	{ letter = "W", count = 2, value = 4 },
	{ letter = "X", count = 1, value = 8 },
	{ letter = "Y", count = 2, value = 4 },
	{ letter = "Z", count = 1, value = 10 },
}

-- Multiplier values
ScrabbleConfig.MULTIPLIERS = {
	TW = { word = 3, letter = 1 },
	DW = { word = 2, letter = 1 },
	TL = { word = 1, letter = 3 },
	DL = { word = 1, letter = 2 },
	CENTER = { word = 2, letter = 1 },
}

-- Standard Scrabble board special tile positions (1-indexed)
ScrabbleConfig.SPECIAL_POSITIONS = {
	-- Triple Word (corners and edges)
	["1,1"] = "TW", ["1,8"] = "TW", ["1,15"] = "TW",
	["8,1"] = "TW", ["8,15"] = "TW",
	["15,1"] = "TW", ["15,8"] = "TW", ["15,15"] = "TW",
	
	-- Double Word (diagonal pattern)
	["2,2"] = "DW", ["3,3"] = "DW", ["4,4"] = "DW", ["5,5"] = "DW",
	["2,14"] = "DW", ["3,13"] = "DW", ["4,12"] = "DW", ["5,11"] = "DW",
	["14,2"] = "DW", ["13,3"] = "DW", ["12,4"] = "DW", ["11,5"] = "DW",
	["14,14"] = "DW", ["13,13"] = "DW", ["12,12"] = "DW", ["11,11"] = "DW",
	
	-- Triple Letter
	["2,6"] = "TL", ["2,10"] = "TL",
	["6,2"] = "TL", ["6,6"] = "TL", ["6,10"] = "TL", ["6,14"] = "TL",
	["10,2"] = "TL", ["10,6"] = "TL", ["10,10"] = "TL", ["10,14"] = "TL",
	["14,6"] = "TL", ["14,10"] = "TL",
	
	-- Double Letter
	["1,4"] = "DL", ["1,12"] = "DL",
	["3,7"] = "DL", ["3,9"] = "DL",
	["4,1"] = "DL", ["4,8"] = "DL", ["4,15"] = "DL",
	["7,3"] = "DL", ["7,7"] = "DL", ["7,9"] = "DL", ["7,13"] = "DL",
	["8,4"] = "DL", ["8,12"] = "DL",
	["9,3"] = "DL", ["9,7"] = "DL", ["9,9"] = "DL", ["9,13"] = "DL",
	["12,1"] = "DL", ["12,8"] = "DL", ["12,15"] = "DL",
	["13,7"] = "DL", ["13,9"] = "DL",
	["15,4"] = "DL", ["15,12"] = "DL",
	
	-- Center
	["8,8"] = "CENTER",
}

-- Build a fresh shuffled bag of tiles
function ScrabbleConfig.buildBag()
	local bag = {}
	for _, item in ipairs(ScrabbleConfig.LETTERS) do
		for _ = 1, item.count do
			table.insert(bag, item.letter)
		end
	end
	-- Fisher-Yates shuffle
	for i = #bag, 2, -1 do
		local j = math.random(i)
		bag[i], bag[j] = bag[j], bag[i]
	end
	return bag
end

-- Get letter value lookup
function ScrabbleConfig.getLetterValues()
	local map = {}
	for _, item in ipairs(ScrabbleConfig.LETTERS) do
		map[item.letter] = item.value
	end
	return map
end

return ScrabbleConfig

