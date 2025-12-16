local ScrabbleDictionary = {
	Dictionary = nil :: { [string]: boolean }?,
	Initialized = false,
}

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
			self.Dictionary[word] = val
			totalCount = totalCount + 1
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
			self.Dictionary[word] = val
			totalCount = totalCount + 1
		end
	else
		warn("[ScrabbleDictionary] Failed to load Words2 module:", words2)
	end
	
	print("[ScrabbleDictionary] Loaded", totalCount, "words")
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
	return self.Dictionary and self.Dictionary[lowerWord] == true
end

return ScrabbleDictionary