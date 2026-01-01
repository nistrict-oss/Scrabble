--[[
	CPUService.luau

	Server-only AI module for CPU players to find and play words in Scrabble.
	Supports Easy, Medium, and Hard difficulty levels.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScrabbleConfig = require(ReplicatedStorage.Shared.Modules.Game.ScrabbleConfig)
local ScrabbleDictionary = require(ReplicatedStorage.Shared.Modules.Game.ScrabbleDictionary)

local BOARD_SIZE = ScrabbleConfig.BOARD_SIZE
local LETTER_VALUES = ScrabbleConfig.getLetterValues()

local CPUService = {}

-- CPU Names by difficulty
CPUService.CPU_NAMES = {
	Easy = { "Rookie Bot", "Beginner Bot", "Newbie AI" },
	Medium = { "Clever Bot", "Smart AI", "Skilled Bot" },
	Hard = { "Expert Bot", "Master AI", "Pro Bot" },
	Impossible = { "Overlord AI", "Supreme Bot", "The Machine" },
}

-- Check if a userId is a CPU (IDs <= -100 are CPUs, to avoid conflicts with Studio test player IDs)
function CPUService.isCPU(userId: number): boolean
	return userId <= -100
end

-- Get CPU name from its ID and difficulty
function CPUService.getCPUName(cpuId: number, difficulty: string): string
	local names = CPUService.CPU_NAMES[difficulty] or CPUService.CPU_NAMES.Medium
	local index = (math.abs(cpuId) - 1) % #names + 1
	return names[index]
end

-- Find all dictionary words that can be made from given letters
-- Scans longer words first to ensure high-scoring moves are prioritized
-- Optimized: pre-filters words that contain unavailable letters
local function findWordsFromLetters(letters: { string }, maxWords: number?): { string }
	if not ScrabbleDictionary.Initialized then
		ScrabbleDictionary:init()
	end

	local limit = maxWords or 100
	local words = {}

	-- Build letter count from rack (for validation)
	local letterCount = {}
	local availableLetters = {} -- Set of letters we have
	for _, letter in ipairs(letters) do
		local l = string.upper(letter)
		letterCount[l] = (letterCount[l] or 0) + 1
		availableLetters[l] = true
	end

	-- Helper: Check if word only uses available letters (fast pre-filter)
	local function hasOnlyAvailableLetters(word)
		for i = 1, #word do
			local c = string.upper(string.sub(word, i, i))
			if not availableLetters[c] then
				return false
			end
		end
		return true
	end

	-- Helper: Check if we have enough of each letter (full validation)
	local function canMakeWord(word)
		local tempCount = table.clone(letterCount)
		for i = 1, #word do
			local c = string.upper(string.sub(word, i, i))
			if (tempCount[c] or 0) > 0 then
				tempCount[c] = tempCount[c] - 1
			else
				return false
			end
		end
		return true
	end

	-- Collect candidate words (pre-filtered by available letters)
	local dictWords = {}
	local scanned = 0
	for word, _ in pairs(ScrabbleDictionary.Dictionary or {}) do
		scanned = scanned + 1
		-- Yield periodically during collection to prevent lag
		if scanned % 5000 == 0 then
			task.wait()
		end
		-- Only include words that:
		-- 1. Are valid length (2+ chars, not longer than rack)
		-- 2. Only contain letters we have in rack
		if #word >= 2 and #word <= #letters and hasOnlyAvailableLetters(word) then
			table.insert(dictWords, word)
		end
	end

	-- Sort by length descending (longer words first)
	table.sort(dictWords, function(a, b)
		return #a > #b
	end)

	-- Validate words (check letter counts, with yield for lag prevention)
	local checked = 0
	for _, word in ipairs(dictWords) do
		checked = checked + 1

		-- Yield periodically to prevent lag
		if checked % 3000 == 0 then
			task.wait()
		end

		-- Full validation: check we have enough of each letter
		if canMakeWord(word) then
			table.insert(words, string.upper(word))
			if #words >= limit then
				break
			end
		end
	end

	return words
end

-- Find all anchor positions where words can be placed
local function findAnchors(board: { { any } }): { { row: number, col: number } }
	local anchors = {}
	local isEmpty = true

	-- Check if board is empty
	for r = 1, BOARD_SIZE do
		for c = 1, BOARD_SIZE do
			if board[r] and board[r][c] then
				isEmpty = false
				break
			end
		end
		if not isEmpty then
			break
		end
	end

	-- If empty, only anchor is center
	if isEmpty then
		return { { row = 8, col = 8 } }
	end

	-- Find all empty cells adjacent to filled cells
	for r = 1, BOARD_SIZE do
		for c = 1, BOARD_SIZE do
			if not (board[r] and board[r][c]) then
				-- Check if adjacent to any filled cell
				local neighbors = {
					{ r - 1, c },
					{ r + 1, c },
					{ r, c - 1 },
					{ r, c + 1 },
				}
				for _, pos in ipairs(neighbors) do
					local nr, nc = pos[1], pos[2]
					if nr >= 1 and nr <= BOARD_SIZE and nc >= 1 and nc <= BOARD_SIZE then
						if board[nr] and board[nr][nc] then
							table.insert(anchors, { row = r, col = c })
							break
						end
					end
				end
			end
		end
	end

	return anchors
end

-- Get the letter from board cell (handles both string and table formats)
local function getBoardLetter(board, row, col): string?
	if not board[row] or not board[row][col] then
		return nil
	end
	local cell = board[row][col]
	if type(cell) == "table" then
		return cell.letter
	end
	return cell
end

-- Get word at position in given direction
local function getWordAt(board, row: number, col: number, dir: string): (string, number, number)
	local word = ""
	local startRow, startCol = row, col

	if dir == "across" then
		startCol = col
		while startCol > 1 and getBoardLetter(board, row, startCol - 1) do
			startCol = startCol - 1
		end
		local c = startCol
		while c <= BOARD_SIZE and getBoardLetter(board, row, c) do
			word = word .. getBoardLetter(board, row, c)
			c = c + 1
		end
		startRow = row
	else -- down
		startRow = row
		while startRow > 1 and getBoardLetter(board, startRow - 1, col) do
			startRow = startRow - 1
		end
		local r = startRow
		while r <= BOARD_SIZE and getBoardLetter(board, r, col) do
			word = word .. getBoardLetter(board, r, col)
			r = r + 1
		end
		startCol = col
	end

	return word, startRow, startCol
end

-- Calculate score for a word placement
local function calculateScore(board, placedTiles, direction, settings): number
	local score = 0
	local wordMult = 1

	-- Create temp board with placed tiles
	local tempBoard = {}
	for r = 1, BOARD_SIZE do
		tempBoard[r] = {}
		for c = 1, BOARD_SIZE do
			tempBoard[r][c] = getBoardLetter(board, r, c)
		end
	end

	for _, tile in ipairs(placedTiles) do
		tempBoard[tile.row][tile.col] = tile.letter
	end

	-- Map of new tile positions
	local newTilesMap = {}
	for _, tile in ipairs(placedTiles) do
		newTilesMap[tile.row .. "," .. tile.col] = true
	end

	local firstTile = placedTiles[1]
	local mainWord, mainStartR, mainStartC = getWordAt(tempBoard, firstTile.row, firstTile.col, direction)

	-- Score main word
	for i = 1, #mainWord do
		local r, c = mainStartR, mainStartC
		if direction == "across" then
			c = mainStartC + i - 1
		else
			r = mainStartR + i - 1
		end

		local letter = string.sub(mainWord, i, i)
		local val = LETTER_VALUES[letter] or 0

		if newTilesMap[r .. "," .. c] then
			local posType = ScrabbleConfig.SPECIAL_POSITIONS[r .. "," .. c]

			if r == 8 and c == 8 then
				local mult = if settings and settings.StarDoublesPoints == false then 1 else 2
				wordMult = wordMult * mult
				score = score + val
			elseif posType then
				local m = ScrabbleConfig.MULTIPLIERS[posType]
				local lMult = m and m.letter or 1
				local wMult = m and m.word or 1
				score = score + val * lMult
				wordMult = wordMult * wMult
			else
				score = score + val
			end
		else
			score = score + val
		end
	end

	score = score * wordMult

	-- Score cross words
	local crossDir = if direction == "across" then "down" else "across"
	for _, tile in ipairs(placedTiles) do
		local crossWord = getWordAt(tempBoard, tile.row, tile.col, crossDir)
		if #crossWord > 1 then
			local crossScore = 0
			local crossWordMult = 1

			local cw, cwStartR, cwStartC = getWordAt(tempBoard, tile.row, tile.col, crossDir)
			for i = 1, #cw do
				local r, c = cwStartR, cwStartC
				if crossDir == "across" then
					c = cwStartC + i - 1
				else
					r = cwStartR + i - 1
				end

				local letter = string.sub(cw, i, i)
				local val = LETTER_VALUES[letter] or 0

				if newTilesMap[r .. "," .. c] then
					local posType = ScrabbleConfig.SPECIAL_POSITIONS[r .. "," .. c]
					if posType then
						local m = ScrabbleConfig.MULTIPLIERS[posType]
						local lMult = m and m.letter or 1
						local wMult = m and m.word or 1
						crossScore = crossScore + val * lMult
						crossWordMult = crossWordMult * wMult
					else
						crossScore = crossScore + val
					end
				else
					crossScore = crossScore + val
				end
			end
			score = score + crossScore * crossWordMult
		end
	end

	-- Bonus for using all 7 tiles
	if #placedTiles == 7 then
		score = score + 50
	end

	return score
end

-- Try to form words starting at an anchor
local function tryPlaceWord(board, rack: { string }, anchor, direction: string, settings): { any }?
	local row, col = anchor.row, anchor.col
	local moves = {}

	-- Simple approach: try placing 1-7 tiles in the direction
	-- For each length, try all permutations of rack letters
	local rackCopy = table.clone(rack)

	-- Collect letters on the board in both directions at/near anchor
	-- This allows the CPU to use these letters to form words
	local boardLettersNearAnchor = {}
	-- Check along the main direction
	for offset = -7, 7 do
		local checkRow = direction == "across" and row or (row + offset)
		local checkCol = direction == "across" and (col + offset) or col
		if checkRow >= 1 and checkRow <= BOARD_SIZE and checkCol >= 1 and checkCol <= BOARD_SIZE then
			local letter = getBoardLetter(board, checkRow, checkCol)
			if letter then
				table.insert(boardLettersNearAnchor, letter)
			end
		end
	end

	-- Combine rack letters with nearby board letters for word finding
	local availableLetters = table.clone(rackCopy)
	for _, letter in ipairs(boardLettersNearAnchor) do
		table.insert(availableLetters, letter)
	end

	-- Try placing tiles from rack
	local function tryPlace(tiles, startPos)
		local placedTiles = {}
		local currentPos = startPos

		for _, letter in ipairs(tiles) do
			-- Skip filled cells
			while true do
				local checkRow = direction == "across" and row or currentPos
				local checkCol = direction == "across" and currentPos or col
				if checkRow < 1 or checkRow > BOARD_SIZE or checkCol < 1 or checkCol > BOARD_SIZE then
					return nil
				end
				if not getBoardLetter(board, checkRow, checkCol) then
					break
				end
				currentPos = currentPos + 1
			end

			local tileRow = direction == "across" and row or currentPos
			local tileCol = direction == "across" and currentPos or col

			if tileRow < 1 or tileRow > BOARD_SIZE or tileCol < 1 or tileCol > BOARD_SIZE then
				return nil
			end

			table.insert(placedTiles, {
				row = tileRow,
				col = tileCol,
				letter = letter,
				originalLetter = letter,
			})
			currentPos = currentPos + 1
		end

		return placedTiles
	end

	-- Find words we can make from available letters (rack + nearby board tiles)
	local validWords = findWordsFromLetters(availableLetters, 100)

	for _, word in ipairs(validWords) do
		-- Figure out which letters from the word we actually need to place from rack
		-- (exclude letters that will come from the board)
		local wordLetters = {}
		local tempRack = table.clone(rackCopy)

		for i = 1, #word do
			local c = string.sub(word, i, i)
			-- Check if this letter is in our rack
			for idx = 1, #tempRack do
				if tempRack[idx] == c then
					table.insert(wordLetters, c)
					table.remove(tempRack, idx)
					break
				end
			end
			-- If not found in rack, the letter must come from the board
			-- The tryPlace function will skip over existing board letters
		end

		-- Only try if we have at least one letter to place
		if #wordLetters == 0 then
			continue
		end

		local startPos = direction == "across" and col or row
		local placedTiles = tryPlace(wordLetters, startPos)

		if placedTiles and #placedTiles > 0 then
			-- Build temp board and validate all words
			local tempBoard = {}
			for r = 1, BOARD_SIZE do
				tempBoard[r] = {}
				for c = 1, BOARD_SIZE do
					tempBoard[r][c] = getBoardLetter(board, r, c)
				end
			end

			for _, tile in ipairs(placedTiles) do
				tempBoard[tile.row][tile.col] = tile.letter
			end

			-- Check main word
			local firstTile = placedTiles[1]
			local mainWord = getWordAt(tempBoard, firstTile.row, firstTile.col, direction)

			if #mainWord >= 2 and ScrabbleDictionary:isWord(mainWord) then
				-- Check all cross words
				local allValid = true
				local crossDir = direction == "across" and "down" or "across"

				for _, tile in ipairs(placedTiles) do
					local crossWord = getWordAt(tempBoard, tile.row, tile.col, crossDir)
					if #crossWord > 1 and not ScrabbleDictionary:isWord(crossWord) then
						allValid = false
						break
					end
				end

				if allValid then
					local score = calculateScore(board, placedTiles, direction, settings)
					table.insert(moves, {
						placedTiles = placedTiles,
						direction = direction,
						score = score,
						word = mainWord,
					})

					-- Early exit: stop after finding enough moves
					if #moves >= 10 then
						return moves
					end
				end
			end
		end
	end

	return moves
end

-- Main function: Find the best move for a CPU player
function CPUService.findBestMove(
	board: { { any } },
	rack: { string },
	difficulty: string,
	settings: any?
): { placedTiles: { any }, direction: string, score: number, word: string }?
	-- Initialize dictionary if needed
	if not ScrabbleDictionary.Initialized then
		ScrabbleDictionary:init()
	end

	-- Start time for timeout
	local startTime = os.clock()

	-- Difficulty-based configuration (including timeout)
	local config = {
		Easy = { maxAnchors = 15, maxMoves = 15, movesPerAnchor = 8, timeout = 15 },
		Medium = { maxAnchors = 20, maxMoves = 25, movesPerAnchor = 10, timeout = 15 },
		Hard = { maxAnchors = 35, maxMoves = 50, movesPerAnchor = 15, timeout = 30 },
		Impossible = { maxAnchors = 50, maxMoves = 100, movesPerAnchor = 25, timeout = 30 },
	}
	local cfg = config[difficulty] or config.Medium
	local MAX_SEARCH_TIME = cfg.timeout

	local anchors = findAnchors(board)
	local allMoves = {}

	-- Limit anchors for performance (shuffle first to get variety)
	if #anchors > cfg.maxAnchors then
		-- Shuffle anchors to get random subset
		for i = #anchors, 2, -1 do
			local j = math.random(i)
			anchors[i], anchors[j] = anchors[j], anchors[i]
		end
		-- Take first N based on difficulty
		local limitedAnchors = {}
		for i = 1, cfg.maxAnchors do
			table.insert(limitedAnchors, anchors[i])
		end
		anchors = limitedAnchors
	end

	-- Try each anchor with both directions
	for _, anchor in ipairs(anchors) do
		task.wait() -- Yield each iteration to prevent lag spikes

		-- Timeout check: stop searching after 15 seconds
		if os.clock() - startTime > MAX_SEARCH_TIME then
			warn("[CPUService] Search timeout - using best moves found so far")
			break
		end

		local acrossMoves = tryPlaceWord(board, rack, anchor, "across", settings)
		local downMoves = tryPlaceWord(board, rack, anchor, "down", settings)

		if acrossMoves then
			for _, move in ipairs(acrossMoves) do
				table.insert(allMoves, move)
			end
		end
		if downMoves then
			for _, move in ipairs(downMoves) do
				table.insert(allMoves, move)
			end
		end

		-- Exit early once we have enough moves
		if #allMoves > cfg.maxMoves then
			break
		end
	end

	if #allMoves == 0 then
		return nil
	end

	-- Sort moves by score
	table.sort(allMoves, function(a, b)
		return a.score > b.score
	end)

	-- Select move based on difficulty
	local selectedMove
	if difficulty == "Easy" then
		-- Easy: 20% chance to skip/exchange instead of playing
		if math.random() < 0.05 then
			return nil -- Will cause CPU to pass
		end
		-- Pick from bottom 40% of moves, prefer short words
		local easyMoves = {}
		for i = math.floor(#allMoves * 0.6), #allMoves do
			if allMoves[i] then
				table.insert(easyMoves, allMoves[i])
			end
		end
		-- Also filter for shorter words
		local shortMoves = {}
		for _, move in ipairs(easyMoves) do
			if #move.word <= 4 then
				table.insert(shortMoves, move)
			end
		end
		if #shortMoves > 0 then
			selectedMove = shortMoves[math.random(#shortMoves)]
		elseif #easyMoves > 0 then
			selectedMove = easyMoves[math.random(#easyMoves)]
		else
			selectedMove = allMoves[#allMoves] -- Lowest score
		end
	elseif difficulty == "Medium" then
		-- Medium: 10% chance to skip/exchange
		if math.random() < 0.025 then
			return nil -- Will cause CPU to pass
		end
		-- Pick from middle 50% randomly
		local startIdx = math.floor(#allMoves * 0.25)
		local endIdx = math.floor(#allMoves * 0.75)
		startIdx = math.max(1, startIdx)
		endIdx = math.max(startIdx, endIdx)
		selectedMove = allMoves[math.random(startIdx, endIdx)]
	elseif difficulty == "Hard" then
		-- Hard: Pick from top 30% randomly (more competitive)
		local endIdx = math.max(1, math.floor(#allMoves * 0.3))
		selectedMove = allMoves[math.random(1, endIdx)]
	else -- Impossible
		-- Always pick the absolute best move
		selectedMove = allMoves[1]
	end

	return selectedMove
end

return CPUService
