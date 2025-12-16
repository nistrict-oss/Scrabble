--[[
	ValidationUtils.luau
	
	Shared validation utilities for math input. Used by both client and server
	to ensure consistent validation behavior.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Modules.Core.GameConstants)

local ValidationUtils = {}

--------------------------------------------------------------------------------
-- MODE-BASED OPERATOR RESTRICTIONS
--------------------------------------------------------------------------------

-- Operators that are only allowed in Hard mode (not in Normal mode)
local HARD_MODE_OPERATORS = {
	["x"] = true,
	["X"] = true,
	["*"] = true,
	["/"] = true,
}

--[[
	Checks if an operator is allowed for the given mode.
	@param char The character to check
	@param mode The game mode ("Normal" or "Hard")
	@return boolean True if the operator is allowed in this mode
]]
function ValidationUtils.isOperatorAllowedForMode(char: string, mode: string?): boolean
	-- If mode is "Normal", block multiplication and division operators
	if mode == "Normal" and HARD_MODE_OPERATORS[char] then
		return false
	end
	return true
end

--------------------------------------------------------------------------------
-- CHARACTER VALIDATION
--------------------------------------------------------------------------------

--[[
	Checks if a character is allowed in math expressions (Easy mode).
	@param char The character to check
	@param mode Optional game mode ("Normal" or "Hard") for operator filtering
	@return boolean True if the character is allowed
]]
function ValidationUtils.isAllowedChar(char: string, mode: string?): boolean
	if not GameConstants.ALLOWED_CHARS[char] then
		return false
	end
	-- Also check mode-based operator restrictions
	return ValidationUtils.isOperatorAllowedForMode(char, mode)
end

--[[
	Converts input characters to display format.
	Specifically converts * and X to lowercase x for multiplication.
	@param char The character to convert
	@return string The display character
]]
function ValidationUtils.convertToDisplay(char: string): string
	if char == "*" or char == "X" then
		return "x"
	end
	return char
end

--------------------------------------------------------------------------------
-- OPERATOR VALIDATION
--------------------------------------------------------------------------------

-- List of binary operators (not including parentheses)
local BINARY_OPERATORS = {
	["+"] = true,
	["-"] = true,
	["x"] = true,
	["X"] = true,
	["*"] = true,
	["/"] = true,
}

--[[
	Counts binary operators in the expression.
	@param text The input text
	@return number The count of operators
]]
function ValidationUtils.countOperators(text: string): number
	local count = 0
	local lastWasOperator = true -- Start true to handle leading minus as unary

	for i = 1, #text do
		local char = string.sub(text, i, i)
		local isOp = BINARY_OPERATORS[char]

		if isOp then
			-- Minus at start or after another operator/open paren is unary, not binary
			local isUnaryMinus = char == "-" and (
				lastWasOperator or 
				i == 1 or 
				(i > 1 and string.sub(text, i - 1, i - 1) == "(")
			)
			
			if not isUnaryMinus then
				count = count + 1
			end
			lastWasOperator = true
		elseif char == "(" then
			lastWasOperator = true
		elseif char == ")" or tonumber(char) then
			lastWasOperator = false
		end
	end

	return count
end

--[[
	Checks if adding a character would exceed the single operator limit.
	@param currentInput The current input string
	@param char The character being added
	@return boolean True if adding the operator should be blocked
]]
function ValidationUtils.wouldExceedOperatorLimit(currentInput: string, char: string): boolean
	-- Only check for operators
	if not BINARY_OPERATORS[char] then
		return false
	end

	-- Check if this would be a unary minus
	if char == "-" then
		if #currentInput == 0 then
			return false -- Leading minus is unary
		end
		local lastChar = string.sub(currentInput, #currentInput, #currentInput)
		if BINARY_OPERATORS[lastChar] or lastChar == "(" then
			return false -- Minus after operator/paren is unary
		end
	end

	-- Count current operators
	local currentCount = ValidationUtils.countOperators(currentInput)
	return currentCount >= 1 -- Block if already have 1 operator
end

--[[
	Checks if an expression has more than one operator.
	@param text The expression to check
	@return boolean True if expression has too many operators
]]
function ValidationUtils.hasTooManyOperators(text: string): boolean
	return ValidationUtils.countOperators(text) > 1
end

--[[
	Checks if an expression contains trivial +0 or -0 operations.
	These operations don't change the value and should be rejected.
	@param text The expression to check
	@return boolean True if expression contains +0 or -0
]]
function ValidationUtils.hasUselessZeroOperation(text: string): boolean
	-- Remove spaces for easier pattern matching
	local clean = string.gsub(text, "%s+", "")

	-- Check for +0 or -0 at the end (e.g., "5+0", "10-0")
	if string.match(clean, "[%+%-]0$") then
		return true
	end

	-- Check for +0 or -0 followed by closing paren (e.g., "(5+0)")
	if string.match(clean, "[%+%-]0%)") then
		return true
	end

	return false
end

--[[
	Checks if an expression has unbalanced parentheses.
	@param text The expression to check
	@return boolean True if parentheses are unbalanced
]]
function ValidationUtils.hasUnbalancedParentheses(text: string): boolean
	local depth = 0
	for i = 1, #text do
		local char = string.sub(text, i, i)
		if char == "(" then
			depth = depth + 1
		elseif char == ")" then
			depth = depth - 1
			if depth < 0 then
				return true -- More closing than opening
			end
		end
	end
	return depth ~= 0 -- Unbalanced if depth isn't 0
end

--------------------------------------------------------------------------------
-- LEADING ZERO VALIDATION
--------------------------------------------------------------------------------

--[[
	Checks if adding a zero would exceed the leading zero limit.
	Prevents inputs like "00" or "+000" but allows "1000".
	
	@param currentInput The current input string
	@return boolean True if adding a zero should be blocked
]]
function ValidationUtils.wouldExceedLeadingZeros(currentInput: string): boolean
	if #currentInput == 0 then
		return false -- First zero is always OK
	end

	-- Walk backwards to find the start of the current number
	local leadingZeros = 0
	local hasNonZeroDigit = false

	for i = #currentInput, 1, -1 do
		local char = string.sub(currentInput, i, i)
		local isOperator = char == "+" or char == "-" or char == "x" or char == "/" or char == "(" or char == ")"

		if isOperator then
			break -- Found start of current number
		elseif char == "0" then
			if not hasNonZeroDigit then
				leadingZeros = leadingZeros + 1
			end
		else
			hasNonZeroDigit = true
		end
	end

	-- If current number has a non-zero digit, zeros are fine (e.g., 1000)
	if hasNonZeroDigit then
		return false
	end

	-- Otherwise, check if we'd exceed leading zero limit
	return leadingZeros >= GameConstants.GAMEPLAY.MAX_LEADING_ZEROS
end

--------------------------------------------------------------------------------
-- INPUT VALIDATION
--------------------------------------------------------------------------------

--[[
	Validates and sanitizes math input.
	Enforces length limits, character restrictions, and leading zero rules.
	
	@param text The raw input text
	@param mode Optional game mode ("Normal" or "Hard") for operator filtering
	@return string The validated and sanitized input
]]
function ValidationUtils.validateMathInput(text: string, mode: string?): string
	local MAX_LENGTH = GameConstants.GAMEPLAY.MAX_INPUT_LENGTH
	local MAX_ZEROS = GameConstants.GAMEPLAY.MAX_LEADING_ZEROS

	-- Enforce max length
	if #text > MAX_LENGTH then
		text = string.sub(text, 1, MAX_LENGTH)
	end

	-- Convert to lowercase for consistent handling
	local lower = string.lower(text)

	-- Only allow whitelisted characters and prevent leading zero spam
	local validated = ""
	local leadingZeros = 0
	local hasNonZeroDigit = false

	for i = 1, #lower do
		local char = string.sub(lower, i, i)
		-- Check if character is allowed (including mode-based restrictions)
		if ValidationUtils.isAllowedChar(char, mode) then
			-- Convert * to x for cleaner display
			local outputChar = ValidationUtils.convertToDisplay(char)

			-- Check if this is an operator (resets number context)
			local isBinaryOp = outputChar == "+" or outputChar == "x" or outputChar == "/"
			local isMinus = outputChar == "-"
			local isParen = outputChar == "(" or outputChar == ")"

			if isBinaryOp or isMinus then
				-- Check single operator limit before adding
				if not ValidationUtils.wouldExceedOperatorLimit(validated, outputChar) then
					leadingZeros = 0
					hasNonZeroDigit = false
					validated = validated .. outputChar
				end
				-- Otherwise skip - already have one operator
			elseif isParen then
				-- Reset for new number
				leadingZeros = 0
				hasNonZeroDigit = false
				validated = validated .. outputChar
			elseif outputChar == "0" then
				if hasNonZeroDigit then
					-- Zeros after a non-zero digit are fine (e.g., 1000)
					validated = validated .. outputChar
				else
					-- Leading zeros - limit them
					leadingZeros = leadingZeros + 1
					if leadingZeros <= MAX_ZEROS then
						validated = validated .. outputChar
					end
				end
			else
				-- Non-zero digit
				hasNonZeroDigit = true
				validated = validated .. outputChar
			end
		end
	end

	return validated
end

--[[
	Validates that an expression only contains allowed characters for Easy mode.
	Also validates length and leading zero limits.
	
	@param expr The expression to validate
	@param mode Optional game mode ("Normal" or "Hard") for operator filtering
	@return boolean True if the expression is valid
]]
function ValidationUtils.isValidEasyExpression(expr: string, mode: string?): boolean
	local MAX_LENGTH = GameConstants.GAMEPLAY.MAX_INPUT_LENGTH
	local MAX_ZEROS = GameConstants.GAMEPLAY.MAX_LEADING_ZEROS

	-- Check length limit
	if #expr > MAX_LENGTH then
		return false
	end

	-- Check for leading zero spam and mode-based operator restrictions
	local leadingZeros = 0
	local hasNonZeroDigit = false

	for i = 1, #expr do
		local char = string.sub(expr, i, i)
		
		-- Check if character is allowed for this mode
		if not ValidationUtils.isOperatorAllowedForMode(char, mode) then
			return false
		end
		
		local isOperator = char == "+"
			or char == "-"
			or char == "x"
			or char == "X"
			or char == "*"
			or char == "/"
			or char == "("
			or char == ")"

		if isOperator or char == " " then
			leadingZeros = 0
			hasNonZeroDigit = false
		elseif char == "0" then
			if not hasNonZeroDigit then
				leadingZeros = leadingZeros + 1
				if leadingZeros > MAX_ZEROS then
					return false
				end
			end
		elseif tonumber(char) then
			hasNonZeroDigit = true
		end
	end

	-- Remove all allowed characters and check if anything remains
	local remaining = expr:gsub("[%d%+%-xX%*/%(%)]", ""):gsub("%s+", "")
	return remaining == ""
end

--[[
	Validates a starting number selection.
	
	@param text The input text
	@return number? The valid number, or nil if invalid
]]
function ValidationUtils.validateStartNumber(text: string): number?
	local value = tonumber(text)
	if not value then
		return nil
	end

	local MIN = GameConstants.GAMEPLAY.MIN_START_NUMBER
	local MAX = GameConstants.GAMEPLAY.MAX_START_NUMBER

	if value < MIN or value > MAX or #text ~= 1 then
		return nil
	end

	return value
end

return ValidationUtils
