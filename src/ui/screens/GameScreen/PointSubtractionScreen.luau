local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ScoreContext = require(ReplicatedStorage.UI.contexts.ScoreContext)
local SoundUtils = require(ReplicatedStorage.Shared.Modules.Core.SoundUtils)

export type PointSubtractionProps = {
	GameState: any,
	OnParticleComplete: (userId: number, amount: number) -> (),
	PlayerGoalPositions: { [number | string]: Vector2 },
	RackTilePositions: { [number]: Vector2 }?, -- For local player
}

return function(props: PointSubtractionProps)
	local spawnParticle = React.useContext(ScoreContext)
	local processedRef = React.useRef({})

	React.useEffect(function()
		local game = props.GameState
		if not game or not game.Penalties or not spawnParticle then
			return
		end

		local penalties = game.Penalties

		for userIdStr, penaltyData in pairs(penalties) do
			if processedRef.current[userIdStr] then
				continue
			end
			processedRef.current[userIdStr] = true

			local userId = tonumber(userIdStr) or userIdStr
			local amount = penaltyData.Amount
			local tiles = penaltyData.Tiles or {}
			local goalPos = props.PlayerGoalPositions[userId] or props.PlayerGoalPositions[tostring(userId)]

			if goalPos and amount > 0 then
				task.delay(1.5, function() -- Wait for "Game Over" swoosh
					-- Calculate how many particles
					local particleCount = math.min(#tiles, amount)
					if particleCount == 0 then
						particleCount = 1
					end
					local scorePerTile = -math.ceil(amount / particleCount) -- Negative score!

					-- Helper to spawn
					local function spawn(idx, startPos)
						local delay = idx * 0.15
						spawnParticle(
							scorePerTile, -- Amount to show (negative)
							startPos,
							goalPos,
							delay,
							function()
								props.OnParticleComplete(userId, scorePerTile)
							end
						)
						-- Play sound for every few particles
						if idx % 2 == 1 then
							SoundUtils.playTilePop()
						end
					end

					-- Determine start position
					if tostring(userId) == tostring(game.LocalUserId) or userId == game.LocalUserId then
						-- Local Player: Spawn from actual rack positions if available
						-- If we have specific tiles, try to match to rack?
						-- For simplicity, just use rack center or spread across rack positions
						local viewportSize = workspace.CurrentCamera.ViewportSize
						local rackCenter = Vector2.new(viewportSize.X * 0.5, viewportSize.Y * 0.9)

						for i = 1, particleCount do
							local pos = rackCenter + Vector2.new((i - particleCount / 2) * 30, 0)
							spawn(i, pos)
						end
					else
						-- Remote Player: Spawn from their Goal Position (Avatar)
						-- Actually, particles usually fly FROM board TO scoreboard.
						-- For penalties, maybe they fall FROM scoreboard?
						-- Or fly FROM rack (invisible) TO scoreboard?
						-- Let's spawn them near the scoreboard entry but slightly offset
						for i = 1, particleCount do
							local offset = Vector2.new(math.random(-20, 20), math.random(-20, 20))
							spawn(i, goalPos + offset)
						end
					end
				end)
			end
		end
	end, { props.GameState.Penalties })

	return nil
end
