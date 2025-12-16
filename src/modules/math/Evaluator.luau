local MathEvaluator = {}

---------------------------------------------------------------------
-- PARENTHESIS STRIPPER
---------------------------------------------------------------------

local function stripParens(s)
	while true do
		local new = s:match("^%((.*)%)$")
		if not new then
			return s
		end
		s = new
	end
end

---------------------------------------------------------------------
-- TOKENIZER
---------------------------------------------------------------------

local function tokenize(str, mode)
	local tokens = {}
	local i = 1
	local lastType = nil

	-- Define allowed operators per mode
	local isNormalMode = mode == "Normal"

	while i <= #str do
		local c = str:sub(i, i)

		if c == " " then
			i += 1

		elseif c:match("[%d%.]") then
			local start = i
			while i <= #str and str:sub(i, i):match("[%d%.]") do
				i += 1
			end
			local num = tonumber(str:sub(start, i - 1))
			table.insert(tokens, { type = "number", value = num })
			lastType = "number"

		elseif c == "-" then
			local isUnary = (lastType == nil) or (lastType == "op") or (lastType == "(") or (lastType == "func")

			if isUnary then
				table.insert(tokens, { type = "op", value = "u-" })
			else
				table.insert(tokens, { type = "op", value = "-" })
			end

			i += 1
			lastType = "op"

		elseif c == "(" then
			table.insert(tokens, { type = "op", value = "(" })
			i += 1
			lastType = "("

		elseif c == ")" then
			table.insert(tokens, { type = "op", value = ")" })
			i += 1
			lastType = ")"

		elseif c == "!" then
			-- Factorial not allowed in Normal mode
			if isNormalMode then
				return nil, "Operator '!' not allowed in Normal mode"
			end
			table.insert(tokens, { type = "op", value = "!" })
			i += 1
			lastType = "op"

		elseif c:match("[%+%*%/%^]") then
			-- Check if operator is allowed in Normal mode
			if isNormalMode and (c == "*" or c == "/" or c == "^") then
				return nil, "Operator '" .. c .. "' not allowed in Normal mode"
			end
			table.insert(tokens, { type = "op", value = c })
			i += 1
			lastType = "op"

		elseif c == "x" or c == "X" then
			-- Treat 'x' as multiplication operator (not allowed in Normal mode)
			if isNormalMode then
				return nil, "Operator 'x' (multiplication) not allowed in Normal mode"
			end
			table.insert(tokens, { type = "op", value = "*" })
			i += 1
			lastType = "op"

		elseif c:match("%a") then
			local start = i
			while i <= #str and str:sub(i, i):match("%a") do
				i += 1
			end
			local fn = str:sub(start, i - 1)
			table.insert(tokens, { type = "func", value = fn })
			lastType = "func"

		else
			return nil, "Invalid character: " .. c
		end
	end

	return tokens
end

---------------------------------------------------------------------
-- PRECEDENCE TABLE
---------------------------------------------------------------------

local precedence = {
	["u-"] = 4,
	["!"] = 4,
	["^"] = 3,
	["*"] = 2,
	["/"] = 2,
	["+"] = 1,
	["-"] = 1,
}

---------------------------------------------------------------------
-- SHUNTING-YARD TO RPN
---------------------------------------------------------------------

local function toRPN(tokens)
	local output = {}
	local stack = {}

	for _, tok in ipairs(tokens) do
		if tok.type == "number" then
			table.insert(output, tok)

		elseif tok.type == "func" then
			table.insert(stack, tok)

		elseif tok.type == "op" then
			local op = tok.value

			if op == "(" then
				table.insert(stack, tok)

			elseif op == ")" then
				while #stack > 0 and stack[#stack].value ~= "(" do
					table.insert(output, table.remove(stack))
				end
				table.remove(stack)
				if #stack > 0 and stack[#stack].type == "func" then
					table.insert(output, table.remove(stack))
				end

			else
				while #stack > 0 do
					local top = stack[#stack]
					if top.type == "op" then
						local pTop = precedence[top.value]
						local pTok = precedence[op]

						if pTop and pTok and pTop >= pTok then
							table.insert(output, table.remove(stack))
						else
							break
						end

					elseif top.type == "func" then
						table.insert(output, table.remove(stack))
					else
						break
					end
				end

				table.insert(stack, tok)
			end
		end
	end

	while #stack > 0 do
		table.insert(output, table.remove(stack))
	end

	return output
end

---------------------------------------------------------------------
-- SAFE FACTORIAL
---------------------------------------------------------------------

local function factorial(n)
	if n < 0 or n > 25 then
		return nil
	end
	local r = 1
	for i = 2, n do
		r *= i
	end
	return r
end

---------------------------------------------------------------------
-- RPN EVALUATOR
---------------------------------------------------------------------

local function evalRPN(rpn, mode)
	local stack = {}

	for _, tok in ipairs(rpn) do
		if tok.type == "number" then
			table.insert(stack, tok.value)

		elseif tok.type == "func" then
			local a = table.remove(stack)
			if not a then return nil end
			local fn = tok.value

			if fn == "sqrt" then
				table.insert(stack, math.sqrt(a))

			elseif fn == "abs" then
				table.insert(stack, math.abs(a))

			elseif fn == "floor" then
				table.insert(stack, math.floor(a))

			elseif fn == "ceil" then
				table.insert(stack, math.ceil(a))

			elseif fn == "round" then
				table.insert(stack, math.floor(a + 0.5))

			elseif fn == "ln" and mode == "advanced" then
				table.insert(stack, math.log(a))

			elseif fn == "log" and mode == "advanced" then
				table.insert(stack, math.log10(a))

			else
				return nil
			end

		elseif tok.type == "op" then
			local op = tok.value

			if op == "u-" then
				local a = table.remove(stack)
				if not a then return nil end
				table.insert(stack, -a)

			elseif op == "!" then
				local a = table.remove(stack)
				table.insert(stack, factorial(a))

			else
				local b = table.remove(stack)
				local a = table.remove(stack)
				if not a or not b then return nil end

				if op == "+" then table.insert(stack, a + b)
				elseif op == "-" then table.insert(stack, a - b)
				elseif op == "*" then table.insert(stack, a * b)
				elseif op == "/" then table.insert(stack, a / b)
				elseif op == "^" then table.insert(stack, a ^ b)
				else return nil end
			end
		end
	end

	return stack[1]
end

---------------------------------------------------------------------
-- CHEAP EXPRESSION DETECTION
---------------------------------------------------------------------

local function isCheap(expr, last)
	local stripped = stripParens(expr)
	if stripped == last then
		return true
	end

	return false
end

---------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------

function MathEvaluator.Evaluate(expr, mode)
	expr = expr:gsub("%s+", "")
	
	-- Convert display symbols to standard operators
	expr = expr:gsub("÷", "/")  -- Division symbol to /
	expr = expr:gsub("×", "*")  -- Multiplication symbol to * (in case it's used)

	local cheap = isCheap(expr)

	-- Pass mode to tokenizer for operator validation
	-- Mode can be "Normal" (+ and - only) or "Hard" (+ - * /)
	local tokens, err = tokenize(expr, mode)
	if not tokens then
		return { value = nil, error = err, cheap = cheap }
	end

	local rpn = toRPN(tokens)
	if not rpn then
		return { value = nil, error = "Invalid expression", cheap = cheap }
	end

	local value = evalRPN(rpn, mode)
	if value == nil then
		return { value = nil, error = "Invalid expression", cheap = cheap }
	end

	return { value = value, error = nil, cheap = cheap }
end

return MathEvaluator
