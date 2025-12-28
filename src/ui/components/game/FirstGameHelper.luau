--[[
	FirstGameHelper.luau
	
	Simple tutorial overlay for first-time players.
	Shows an animated cursor demonstrating how to drag letters from rack to board.
	Phase 1: Cursor moves from rack to board center
	Phase 2: Once tile is placed, cursor moves to Play button
	Only shows on the first turn when the board is empty.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)
local LetterTile = require(ReplicatedStorage.UI.components.game.LetterTile)

local e = React.createElement

local ANIM_DURATION = 1.5 -- seconds for drag animation
local PAUSE_AT_START = 0.5 -- pause at start position
local PAUSE_AT_END = 0.5 -- pause at end position

export type FirstGameHelperProps = {
	Rack: { string },
	PlacedTiles: { { row: number, col: number, letter: string, rackIndex: number } }?,
	PlacedTilesCount: number,
	IsWordValid: boolean,
	IsBoardEmpty: boolean?, -- Only show when board is empty (first word)
	BoardPositions: { [string]: Vector2 }, -- Actual board tile absolute positions
	RackPositions: { [number]: Vector2 }?, -- Actual rack tile absolute positions
	PlayButtonPosition: Vector2?, -- Actual Play button center position
	OnDismiss: () -> (),
}

return function(props: FirstGameHelperProps)
	local rack = props.Rack or {}
	local placedCount = props.PlacedTilesCount or 0
	local isBoardEmpty = props.IsBoardEmpty ~= false
	local rackPositions = props.RackPositions or {}
	local onDismiss = props.OnDismiss

	-- Animation progress
	local animProgress, setAnimProgress = React.useState(0)

	-- Get positions for animation
	local firstRackPos = rackPositions[1] or Vector2.new(0, 0)
	local firstLetter = rack[1] or "A"

	-- Determine which phase we're in
	local isPhase1 = placedCount == 0 and isBoardEmpty -- Rack to board

	-- Continuous animation loop
	React.useEffect(function()
		if not isBoardEmpty then
			return
		end

		local cycleDuration = PAUSE_AT_START + ANIM_DURATION + PAUSE_AT_END
		local startTime = tick()

		local connection = RunService.RenderStepped:Connect(function()
			local elapsed = tick() - startTime
			local cycleTime = elapsed % cycleDuration

			-- Calculate progress within this animation cycle
			if cycleTime < PAUSE_AT_START then
				setAnimProgress(0)
			elseif cycleTime < PAUSE_AT_START + ANIM_DURATION then
				local dragTime = cycleTime - PAUSE_AT_START
				local progress = dragTime / ANIM_DURATION
				-- Ease out cubic for smooth motion
				local eased = 1 - math.pow(1 - progress, 3)
				setAnimProgress(eased)
			else
				setAnimProgress(1)
			end
		end)

		return function()
			connection:Disconnect()
		end
	end, { isBoardEmpty })

	-- Auto-dismiss when player submits their word (tutorial complete)
	React.useEffect(function()
		-- Only auto-dismiss after they've placed tiles AND board is no longer empty (word submitted)
		if not isBoardEmpty and onDismiss then
			onDismiss()
		end
	end, { isBoardEmpty })

	-- Account for GUI inset
	local GUI_INSET = -40

	-- Calculate positions based on phase
	local startPos, endPos
	-- Phase 1 Only: Rack to generic "up on board" position
	-- Just dragging up to show "drag me" hint
	startPos = firstRackPos
	endPos = Vector2.new(firstRackPos.X, firstRackPos.Y - 100)

	local currentX = startPos.X + (endPos.X - startPos.X) * animProgress
	local currentY = startPos.Y + (endPos.Y - startPos.Y) * animProgress - GUI_INSET

	-- Check if we have valid positions to show animation
	local hasValidPositions = startPos.X > 0 and endPos.X > 0

	-- Determine if cursor should be shown:
	-- Only show if nothing is placed yet (drag hint). Once they place a tile, stop showing hints.
	local showCursor = hasValidPositions and isBoardEmpty and placedCount == 0

	-- Mouse cursor icon
	local cursorIcon = "rbxassetid://79181432150021"

	-- Calculate ghost tile position (slightly offset from cursor for visual clarity)
	-- Only show ghost tile during phase 1
	local ghostTileX = currentX + 15
	local ghostTileY = currentY + 25

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,
		ZIndex = 50,
	}, {
		-- Animated cursor
		DragCursor = showCursor and e("ImageLabel", {
			Size = UDim2.fromOffset(50, 50),
			Position = UDim2.fromOffset(currentX, currentY),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Image = cursorIcon,
			ImageColor3 = Color3.new(1, 1, 1),
			ZIndex = 100,
		}, {
			UIAspectRatioConstraint = e("UIAspectRatioConstraint", { AspectRatio = 1 }),
		}) or nil,

		-- Ghost tile being "dragged" with cursor (only in phase 1)
		DraggedTile = isPhase1 and hasValidPositions and animProgress > 0 and e("Frame", {
			Size = UDim2.fromOffset(45, 45),
			Position = UDim2.fromOffset(ghostTileX, ghostTileY),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			ZIndex = 99,
		}, {
			Tile = e(LetterTile, {
				Letter = firstLetter,
				Index = 1,
				IsDragging = true,
			}),
		}) or nil,
	})
end
