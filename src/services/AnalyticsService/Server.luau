--[[
	AnalyticsServiceServer.luau
	
	Centralized analytics tracking using Roblox's AnalyticsService.
	Tracks player behavior, engagement, monetization, and pain points.
	
	Events are viewable in the Creator Dashboard under Analytics > Custom Events.
]]

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")

local AnalyticsServiceServer = {}

-- Rate limiting to prevent hitting Roblox limits (~120 events/min per player)
local playerEventCounts = {} :: {[number]: {count: number, resetTime: number}}
local MAX_EVENTS_PER_MINUTE = 100 -- Leave some headroom

local function canLogEvent(player: Player): boolean
	local userId = player.UserId
	local now = tick()
	
	local data = playerEventCounts[userId]
	if not data or now > data.resetTime then
		playerEventCounts[userId] = { count = 0, resetTime = now + 60 }
		data = playerEventCounts[userId]
	end
	
	if data.count >= MAX_EVENTS_PER_MINUTE then 
		return false
	end
	
	data.count += 1
	return true
end

-- Safe wrapper for logging events
local function logEvent(player: Player, eventName: string, value: number?, customFields: {[string]: any}?)
	if not canLogEvent(player) then return end
	
	local success, err = pcall(function()
		AnalyticsService:LogCustomEvent(player, eventName, value or 1, customFields)
	end)
	
	if not success then
		warn("[Analytics] Failed to log event:", eventName, err)
	end
end

--------------------------------------------------------------------------------
-- TUTORIAL EVENTS
--------------------------------------------------------------------------------

function AnalyticsServiceServer:trackTutorialStarted(player: Player)
	logEvent(player, "TutorialStarted")
end

function AnalyticsServiceServer:trackTutorialStepViewed(player: Player, stepId: string, stepNumber: number)
	logEvent(player, "TutorialStep", stepNumber, { step = stepId })
end

function AnalyticsServiceServer:trackTutorialCompleted(player: Player)
	logEvent(player, "TutorialCompleted")
end

function AnalyticsServiceServer:trackTutorialSkipped(player: Player, atStep: number?)
	logEvent(player, "TutorialSkipped", atStep or 1)
end

--------------------------------------------------------------------------------
-- GAME ENGAGEMENT EVENTS
--------------------------------------------------------------------------------

function AnalyticsServiceServer:trackGameStarted(player: Player, mode: string, playerCount: number)
	logEvent(player, "GameStarted", playerCount, { mode = mode })
end

function AnalyticsServiceServer:trackGameEnded(player: Player, result: string, roundsSurvived: number, mode: string)
	-- result: "win", "loss", "quit"
	logEvent(player, "GameEnded", roundsSurvived, { result = result, mode = mode })
end

function AnalyticsServiceServer:trackRoundCompleted(player: Player, roundNumber: number, wasDefender: boolean, survived: boolean)
	logEvent(player, "RoundCompleted", roundNumber, { 
		role = if wasDefender then "defender" else "attacker",
		survived = if survived then "yes" else "no"
	})
end

function AnalyticsServiceServer:trackAnswerSubmitted(player: Player, correct: boolean, responseTimeMs: number?)
	logEvent(player, "AnswerSubmitted", responseTimeMs or 0, { 
		correct = if correct then "yes" else "no" 
	})
end

function AnalyticsServiceServer:trackExpressionRejected(player: Player, reason: string)
	-- reason: "already_used", "wrong_answer", "invalid_syntax", "too_simple"
	logEvent(player, "ExpressionRejected", 1, { reason = reason })
end

function AnalyticsServiceServer:trackExpressionHintShown(player: Player)
	logEvent(player, "ExpressionHintShown")
end

function AnalyticsServiceServer:trackAbilityUsed(player: Player, abilityName: string, success: boolean)
	logEvent(player, "AbilityUsed", 1, { 
		ability = abilityName,
		success = if success then "yes" else "no"
	})
end

function AnalyticsServiceServer:trackModeSelected(player: Player, mode: string)
	logEvent(player, "ModeSelected", 1, { mode = mode })
end

--------------------------------------------------------------------------------
-- MONETIZATION EVENTS
--------------------------------------------------------------------------------

function AnalyticsServiceServer:trackPurchaseStarted(player: Player, productType: string, productId: string, price: number?)
	-- productType: "gamepass", "devproduct", "donation"
	logEvent(player, "PurchaseStarted", price or 0, { 
		type = productType,
		product = productId 
	})
end

function AnalyticsServiceServer:trackPurchaseCompleted(player: Player, productType: string, productId: string, price: number)
	logEvent(player, "PurchaseCompleted", price, { 
		type = productType,
		product = productId 
	})
end

function AnalyticsServiceServer:trackDonation(player: Player, amount: number)
	logEvent(player, "Donation", amount)
end

function AnalyticsServiceServer:trackSpinPurchased(player: Player, cost: number, result: string?)
	logEvent(player, "SpinPurchased", cost, { result = result or "unknown" })
end

--------------------------------------------------------------------------------
-- RETENTION & SESSION EVENTS
--------------------------------------------------------------------------------

function AnalyticsServiceServer:trackSessionStart(player: Player, isReturning: boolean, daysSinceLastVisit: number?)
	logEvent(player, "SessionStart", daysSinceLastVisit or 0, { 
		returning = if isReturning then "yes" else "no" 
	})
end

function AnalyticsServiceServer:trackDailyRewardClaimed(player: Player, streakDay: number)
	logEvent(player, "DailyRewardClaimed", streakDay)
end

function AnalyticsServiceServer:trackCodeRedeemed(player: Player, code: string, reward: string)
	logEvent(player, "CodeRedeemed", 1, { reward = reward })
end

--------------------------------------------------------------------------------
-- PROGRESSION EVENTS
--------------------------------------------------------------------------------

function AnalyticsServiceServer:trackLevelUp(player: Player, stat: string, newValue: number)
	-- stat: "wins", "streak", "games_played"
	logEvent(player, "Milestone", newValue, { stat = stat })
end

function AnalyticsServiceServer:trackFirstWin(player: Player)
	logEvent(player, "FirstWin")
end

function AnalyticsServiceServer:trackStreakMilestone(player: Player, streak: number)
	logEvent(player, "StreakMilestone", streak)
end

--------------------------------------------------------------------------------
-- PAIN POINT / CHURN EVENTS
--------------------------------------------------------------------------------

function AnalyticsServiceServer:trackQuitMidGame(player: Player, roundNumber: number, mode: string)
	logEvent(player, "QuitMidGame", roundNumber, { mode = mode })
end

function AnalyticsServiceServer:trackTableLeft(player: Player, reason: string?)
	-- reason: "manual", "kicked", "timeout"
	logEvent(player, "TableLeft", 1, { reason = reason or "manual" })
end

function AnalyticsServiceServer:trackFrustrationSignal(player: Player, signal: string)
	-- signal: "rapid_wrong_answers", "rage_quit", "repeated_mistakes"
	logEvent(player, "FrustrationSignal", 1, { signal = signal })
end

--------------------------------------------------------------------------------
-- UI/UX EVENTS
--------------------------------------------------------------------------------

function AnalyticsServiceServer:trackSettingChanged(player: Player, setting: string, newValue: any)
	local valueStr = tostring(newValue)
	logEvent(player, "SettingChanged", 1, { setting = setting, value = valueStr })
end

function AnalyticsServiceServer:trackUIOpened(player: Player, panelName: string)
	logEvent(player, "UIOpened", 1, { panel = panelName })
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function AnalyticsServiceServer:init()
	-- Clean up rate limiting data when players leave
	Players.PlayerRemoving:Connect(function(player)
		playerEventCounts[player.UserId] = nil
	end)
end

return AnalyticsServiceServer

