-- Codes configuration for the game
-- Players can redeem codes for rewards

export type CodeReward = {
	type: "cash" | "gun" | "skin" | "luckyspins",
	amount: number?, -- for cash or luckyspins
	itemId: string?, -- for gun/skin
}

export type Code = {
	id: string,
	reward: CodeReward,
	bonusReward: CodeReward?, -- Optional additional reward
	maxUses: number?, -- nil = unlimited
	expiresAt: number?, -- Unix timestamp, nil = never expires
	active: boolean,
}

local Codes = {
	-- Launch code
	RELEASE = {
		id = "RELEASE",
		reward = {
			type = "cash",
			amount = 1000,
		},
		bonusReward = {
			type = "luckyspins",
			amount = 3,
		},
		maxUses = nil, -- Unlimited
		expiresAt = nil, -- Never expires
		active = true,
	},
	
	-- Example future codes (inactive for now)
	-- SUMMER2025 = {
	-- 	id = "SUMMER2025",
	-- 	reward = {
	-- 		type = "cash",
	-- 		amount = 500,
	-- 	},
	-- 	maxUses = 10000,
	-- 	expiresAt = 1756684800, -- Sept 1, 2025
	-- 	active = false,
	-- },
}

-- Validate a code exists and is active
function Codes.isValid(codeId: string): boolean
	local code = Codes[string.upper(codeId)]
	if not code then return false end
	if not code.active then return false end
	
	-- Check expiration
	if code.expiresAt and os.time() > code.expiresAt then
		return false
	end
	
	return true
end

-- Get code info (returns nil if not found or inactive)
function Codes.getCode(codeId: string): Code?
	local code = Codes[string.upper(codeId)]
	if not code or not code.active then return nil end
	
	-- Check expiration
	if code.expiresAt and os.time() > code.expiresAt then
		return nil
	end
	
	return code
end

return Codes

