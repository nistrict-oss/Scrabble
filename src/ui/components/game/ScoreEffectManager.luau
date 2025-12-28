--[[
	ScoreEffectManager.luau
	
	Container component that renders active ScoreParticles.
	Exposes an imperative API via a Ref for spawning new effects.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ScoreParticle = require(script.Parent.ScoreParticle)

local e = React.createElement

export type ParticleData = {
	id: string,
	amount: number,
	startPos: Vector2,
	endPos: Vector2,
	delay: number?,
	tileIndex: number?,
	totalTiles: number?,
	onComplete: (() -> ())?,
}

return React.forwardRef(function(_, ref)
	local particles, setParticles = React.useState({} :: { [string]: ParticleData })

	-- Expose spawn method
	React.useImperativeHandle(ref, function()
		return {
			spawn = function(
				amount: number,
				startPos: Vector2,
				endPos: Vector2,
				delay: number?,
				onComplete: (() -> ())?,
				tileIndex: number?,
				totalTiles: number?
			)
				local id = game:GetService("HttpService"):GenerateGUID()
				setParticles(function(prev)
					local next = table.clone(prev)
					next[id] = {
						id = id,
						amount = amount,
						startPos = startPos,
						endPos = endPos,
						delay = delay,
						tileIndex = tileIndex,
						totalTiles = totalTiles,
						onComplete = onComplete,
					}
					return next
				end)
			end,
			clear = function()
				setParticles({})
			end,
		}
	end, {})

	local children = {}
	for id, data in pairs(particles) do
		children[id] = e(ScoreParticle, {
			Amount = data.amount,
			StartPos = data.startPos,
			EndPos = data.endPos,
			Delay = data.delay,
			TileIndex = data.tileIndex,
			TotalTiles = data.totalTiles,
			OnComplete = function()
				if data.onComplete then
					data.onComplete()
				end
				setParticles(function(prev)
					local next = table.clone(prev)
					next[id] = nil
					return next
				end)
			end,
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,
		ZIndex = 100, -- Higher than normal UI
		ClipsDescendants = false,
	}, children)
end)
