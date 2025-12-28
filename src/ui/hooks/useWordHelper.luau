--[[
	useWordHelper.luau
	
	Hook for detecting playable words from the player's rack.
	Used by the FirstGameHelper to suggest words to new players.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ScrabbleDictionary = require(ReplicatedStorage.Shared.Modules.Game.ScrabbleDictionary)

local function useWordHelper(rack: { string }): { word: string?, letters: { string }?, hasWord: boolean }
	-- Create a stable key from rack contents for proper dependency tracking
	local rackKey = table.concat(rack or {}, ",")
	local result, setResult = React.useState({ word = nil :: string?, letters = nil :: { string }?, hasWord = false })

	React.useEffect(function()
		if not rack or #rack == 0 then
			setResult({ word = nil, letters = nil, hasWord = false })
			return
		end

		-- Initialize dictionary if needed
		if not ScrabbleDictionary.Initialized then
			ScrabbleDictionary:init()
		end

		-- Build letter count from rack
		local letterCount = {}
		for _, letter in ipairs(rack) do
			local l = string.upper(letter)
			letterCount[l] = (letterCount[l] or 0) + 1
		end

		-- Find a simple 2-4 letter word that can be made from rack
		-- Group words by length and search progressively for better results
		local foundWord = nil
		local dictionary = ScrabbleDictionary.Dictionary or {}

		-- Helper to check if a word can be made from the rack
		local function canMakeWord(word: string): boolean
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

		-- Search by word length (2, then 3, then 4) to find shortest playable words first
		for targetLen = 2, 4 do
			if foundWord then
				break
			end

			local checked = 0
			for word, _ in pairs(dictionary) do
				checked = checked + 1

				-- Check more words per length tier
				if checked > 20000 then
					break
				end

				-- Only check words of the current target length
				if #word == targetLen and targetLen <= #rack then
					if canMakeWord(word) then
						foundWord = string.upper(word)
						break
					end
				end
			end
		end

		if foundWord then
			-- Build the letters array from the word
			local letters = {}
			for i = 1, #foundWord do
				table.insert(letters, string.sub(foundWord, i, i))
			end
			setResult({ word = foundWord, letters = letters, hasWord = true })
		else
			setResult({ word = nil, letters = nil, hasWord = false })
		end
	end, { rackKey })

	return result
end

return useWordHelper
