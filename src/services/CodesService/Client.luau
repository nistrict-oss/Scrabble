local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)

local CodesServiceClient = {
	Networker = nil,
	
	-- Signals
	OnCodeResult = Signal.new(),
	
	-- State
	_lastResult = nil,
	_lastMessage = nil,
}

export type CodesServiceClient = typeof(CodesServiceClient) & {
	Networker: Networker.Client,
}

function CodesServiceClient.init(self: CodesServiceClient)
	self.Networker = Networker.client.new("CodesService", self)
end

-- Called by Networker when server fires "CodeResult"
function CodesServiceClient.CodeResult(self: CodesServiceClient, success: boolean, message: string)
	self._lastResult = success
	self._lastMessage = message
	self.OnCodeResult:Fire(success, message)
end

function CodesServiceClient.redeemCode(self: CodesServiceClient, code: string): (boolean, string)
	if not code or code == "" then
		return false, "Please enter a code"
	end
	
	-- Reset last result
	self._lastResult = nil
	self._lastMessage = nil
	
	-- Send to server
	self.Networker:fire("RedeemCode", code)
	
	-- Wait for response (with timeout)
	local startTime = tick()
	while self._lastResult == nil and (tick() - startTime) < 5 do
		task.wait(0.1)
	end
	
	if self._lastResult == nil then
		return false, "Request timed out"
	end
	
	return self._lastResult, self._lastMessage or ""
end

return CodesServiceClient

