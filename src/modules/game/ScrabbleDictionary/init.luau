local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local BANNED_WORDS = require(ReplicatedStorage.Shared.Modules.Game.ScrabbleDictionary.BannedWords)

local ScrabbleDictionary = {
	Dictionary = nil :: { [string]: boolean }?,
	Initialized = false,
	FilterCache = {} :: { [string]: boolean }, -- Cache for Roblox filter results
}

-- Check if a word passes Roblox's text filter (server-only, logging only)
-- NOTE: This only logs warnings, doesn't block words. BANNED_WORDS is the primary filter.
local function checkRobloxFilter(word: string)
	-- Only run on server
	if not RunService:IsServer() then
		return
	end

	-- Check cache first
	if ScrabbleDictionary.FilterCache[word] ~= nil then
		return
	end

	-- Run filter check in background (non-blocking)
	task.spawn(function()
		local success, result = pcall(function()
			local filterResult = TextService:FilterStringAsync(word, 0)
			local filteredText = filterResult:GetNonChatStringForBroadcastAsync()
			return filteredText == word
		end)

		local passed = success and result
		ScrabbleDictionary.FilterCache[word] = passed

		if not passed and success then
			-- Log for review but don't block - BANNED_WORDS is authoritative
			warn("[ScrabbleDictionary] Word flagged by Roblox filter (review for BANNED_WORDS):", word)
		end
	end)
end

function ScrabbleDictionary:init()
	if self.Initialized then
		return
	end

	self.Dictionary = {}
	local totalCount = 0

	-- Load Words.luau (first half)
	local success1, words1 = pcall(function()
		return require(script.Words)
	end)

	if success1 and words1 then
		for word, val in pairs(words1) do
			if not BANNED_WORDS[string.lower(word)] then
				self.Dictionary[word] = val
				totalCount = totalCount + 1
			end
		end
	else
		warn("[ScrabbleDictionary] Failed to load Words module:", words1)
	end

	-- Load Words2.luau (second half)
	local success2, words2 = pcall(function()
		return require(script.Words2)
	end)

	if success2 and words2 then
		for word, val in pairs(words2) do
			if not BANNED_WORDS[string.lower(word)] then
				self.Dictionary[word] = val
				totalCount = totalCount + 1
			end
		end
	else
		warn("[ScrabbleDictionary] Failed to load Words2 module:", words2)
	end

	self.Initialized = true
end

function ScrabbleDictionary:isWord(word: string): boolean
	if not self.Initialized then
		self:init()
	end

	if #word < 2 then
		return false
	end

	local lowerWord = string.lower(word)

	-- Check if it's in the dictionary
	if not (self.Dictionary and self.Dictionary[lowerWord] == true) then
		return false
	end

	-- Run Roblox filter check in background (non-blocking, logging only)
	-- BANNED_WORDS is the authoritative filter, this just logs for review
	checkRobloxFilter(lowerWord)

	return true
end

return ScrabbleDictionary
