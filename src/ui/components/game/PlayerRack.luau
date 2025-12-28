--[[
	PlayerRack.luau
	
	UI component for the player's tile rack.
	Handles displaying tiles, selection, and drag logic.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)
local LetterTile = require(ReplicatedStorage.UI.components.game.LetterTile)
local SoundUtils = require(ReplicatedStorage.Shared.Modules.Core.SoundUtils)

local e = React.createElement

local MAX_TILES = 7
local ANIMATION_DURATION = 0.3

export type PlayerRackProps = {
	Letters: { { id: number, letter: string } }, -- Array of stable tile objects
	SelectedIndex: number?,
	DraggingIndex: number?,
	IsDragging: boolean?,
	IsDisabled: boolean?,
	IsExchangeMode: boolean?,
	ExchangeSelection: { [number]: boolean }?,
	PlacedTiles: { { rackIndex: number, letter: string, row: number, col: number } }?,
	IsWordValid: boolean?,
	HiddenIndices: { [number]: boolean }?,
	OnTileClick: ((number, string) -> ())?,
	OnDragStart: ((number, string) -> ())?,
	OnDropToRack: (() -> ())?,
	OnExchangeToggle: ((number) -> ())?,
	OnReportPosition: ((index: number, pos: Vector2) -> ())?,
	RackVersions: { number }?,
}

local function AnimatedTile(tileProps: {
	Letter: string,
	Index: number,
	TotalTiles: number,
	TargetX: number,
	TargetScale: number,
	IsSelected: boolean?,
	IsDragging: boolean?,
	IsDisabled: boolean?,
	IsNew: boolean?,
	OverrideColor: Color3?,
	EntryDelay: number?,
	OnClick: ((number, string) -> ())?,
	OnDragStart: ((number, string) -> ())?,
	OnReportPosition: ((index: number, pos: Vector2) -> ())?,
})
	local tileWidth = 1 / MAX_TILES
	local targetX = tileProps.TargetX
	local targetScale = tileProps.TargetScale

	-- Initialize at target position.
	-- If it's a NEW tile (just entered rack), start it off-screen to the right.
	-- Otherwise, start it where it should be, and let useEffect animate any changes.
	local initialX = if tileProps.IsNew and targetScale > 0.5 then 1.2 else targetX
	local initialScale = if tileProps.IsNew and targetScale > 0.5 then 0.5 else targetScale

	local currentX, setCurrentX = React.useState(initialX)
	local currentScale, setCurrentScale = React.useState(initialScale)
	local animConnection = React.useRef(nil)

	-- Animate to target position whenever it changes
	React.useEffect(function()
		-- Always cancel existing animation
		if animConnection.current then
			animConnection.current:Disconnect()
			animConnection.current = nil
		end

		local needsAnimation = math.abs(currentX - targetX) > 0.005 or math.abs(currentScale - targetScale) > 0.005

		if needsAnimation then
			local delayTime = tileProps.EntryDelay or 0
			local startXVal = currentX
			local startScaleVal = currentScale
			local startTime = tick() + delayTime
			local soundPlayed = false -- Prevent multiple woosh sounds

			animConnection.current = RunService.Heartbeat:Connect(function()
				local now = tick()
				if now < startTime then
					return
				end

				-- Play woosh sound only once at animation start
				if not soundPlayed and tileProps.IsNew then
					soundPlayed = true
					SoundUtils.playWoosh()
				end

				local elapsed = now - startTime
				local alpha = math.min(elapsed / ANIMATION_DURATION, 1)

				-- Smooth ease-out cubic
				local easedAlpha = 1 - math.pow(1 - alpha, 3)

				local newX = startXVal + (targetX - startXVal) * easedAlpha
				local newScale = startScaleVal + (targetScale - startScaleVal) * easedAlpha -- Corrected: targetScale - startScaleVal

				setCurrentX(newX)
				setCurrentScale(newScale) -- Moved this line back

				if alpha >= 1 then
					setCurrentX(targetX)
					setCurrentScale(targetScale)
					if animConnection.current then
						animConnection.current:Disconnect()
						animConnection.current = nil
					end
				end
			end)
		else
			-- Snap to target if very close
			setCurrentX(targetX)
			setCurrentScale(targetScale)
		end

		return function()
			if animConnection.current then
				animConnection.current:Disconnect()
				animConnection.current = nil
			end
		end
	end, { targetX, targetScale, tileProps.EntryDelay })

	return e("Frame", {
		Size = UDim2.fromScale(tileWidth * currentScale, currentScale),
		Position = UDim2.fromScale(currentX, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		ZIndex = if tileProps.IsDragging then 10 else 1,
		Visible = currentScale > 0.1,
		[React.Change.AbsolutePosition] = function(rbx)
			if tileProps.OnReportPosition and currentScale > 0.5 then
				local pos = rbx.AbsolutePosition + rbx.AbsoluteSize / 2
				tileProps.OnReportPosition(tileProps.Index, pos)
			end
		end,
	}, {
		Content = e(LetterTile, {
			Letter = tileProps.Letter,
			Index = tileProps.Index,
			IsSelected = tileProps.IsSelected,
			IsDragging = tileProps.IsDragging,
			IsDisabled = tileProps.IsDisabled,
			IsNew = false,
			NoPop = true,
			Active = targetScale > 0.5, -- Only responsive when visible
			OverrideColor = tileProps.OverrideColor,
			OnClick = tileProps.OnClick,
			OnDragStart = tileProps.OnDragStart,
		}),

		UIPadding = e("UIPadding", {
			PaddingBottom = UDim.new(0.05, 0),
			PaddingTop = UDim.new(0.05, 0),
			PaddingLeft = UDim.new(0.02, 0),
			PaddingRight = UDim.new(0.02, 0),
		}),
	})
end

return function(props: PlayerRackProps)
	local letters = props.Letters or {}
	local selectedIndex = props.SelectedIndex
	local draggingIndex = props.DraggingIndex
	local isDisabled = props.IsDisabled
	local isExchangeMode = props.IsExchangeMode
	local exchangeSelection = props.ExchangeSelection or {}
	local placedTiles = props.PlacedTiles or {}
	local isWordValid = props.IsWordValid

	-- Only swipe animation when a slot is refilled with a new letter (from bag/swap)
	local lastLetterMap = React.useRef({} :: { [number]: string })
	local newTileIndices = React.useMemo(function()
		local indices = {}
		for i, t in ipairs(letters) do
			if not lastLetterMap.current[t.id] or (lastLetterMap.current[t.id] ~= t.letter) then
				indices[i] = true
			end
		end
		return indices
	end, { letters })

	-- Update last letters in an effect to keep render pure
	React.useEffect(function()
		local newMap = {}
		for _, t in ipairs(letters or {}) do
			newMap[t.id] = t.letter
		end
		lastLetterMap.current = newMap
	end, { letters })

	local hiddenIndices = props.HiddenIndices or {}
	local visibleCount = 0
	for _, tile in ipairs(letters) do
		if not hiddenIndices[tile.id] then
			visibleCount += 1
		end
	end

	local tileWidth = 1 / MAX_TILES
	local startX = (1 - (visibleCount * tileWidth)) / 2

	local visibleIndex = 0
	local tiles = {}
	for i, tileInfo in ipairs(letters) do
		local id = tileInfo.id
		local letter = tileInfo.letter
		local isSelectedForExchange = exchangeSelection[id] == true
		local isNewTile = newTileIndices[i] == true
		local isHidden = hiddenIndices[id] == true

		if not isHidden then
			visibleIndex += 1
		end

		-- Target position:
		-- Visible tiles spread out.
		-- Hidden tiles stack behind the previous visible tile to avoid jumping.
		local targetX = startX + (visibleIndex - 0.5) * tileWidth
		local targetScale = if isHidden then 0 else 1

		local function handleExchangeClick(clickedId: number, _letter: string)
			if props.OnExchangeToggle then
				props.OnExchangeToggle(clickedId)
			end
		end

		-- Check if this tile is currently on the board (even if hidden in rack)
		local overrideColor = nil
		if isExchangeMode then
			local isOnBoard = false
			for _, p in ipairs(placedTiles) do
				if p.rackIndex == id then
					isOnBoard = true
					break
				end
			end

			if isOnBoard then
				overrideColor = if isWordValid then Color3.fromRGB(100, 200, 100) else Color3.fromRGB(220, 100, 100)
			end
		end

		table.insert(
			tiles,
			e(AnimatedTile, {
				key = "Tile_" .. tostring(id) .. "_" .. (props.RackVersions and props.RackVersions[id] or 0),
				Letter = letter,
				Index = id,
				TotalTiles = #letters,
				TargetX = targetX,
				TargetScale = targetScale,
				IsSelected = if isExchangeMode then isSelectedForExchange else (selectedIndex == id),
				IsDragging = draggingIndex == id,
				IsDisabled = isDisabled,
				IsNew = isNewTile,
				EntryDelay = if isNewTile then (i - 1) * 0.1 else 0,
				OverrideColor = overrideColor,
				OnClick = if isExchangeMode then handleExchangeClick else props.OnTileClick,
				OnDragStart = if isExchangeMode then nil else props.OnDragStart,
				OnReportPosition = props.OnReportPosition,
			})
		)
	end

	return e("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		[React.Event.Activated] = props.OnDropToRack,
	}, {
		Background = e("Frame", {
			Size = UDim2.fromScale(1, 0.45),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(40, 30, 20),
			ZIndex = 0,
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0.2, 0),
			}),
			UIStroke = e("UIStroke", {
				Color = Color3.fromRGB(60, 45, 30),
				Thickness = 2,
			}),
		}),

		TileContainer = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ClipsDescendants = false,
		}, tiles),

		StrategyHint = if isDisabled
			then e("TextLabel", {
				Size = UDim2.fromScale(1, 0.05),
				Position = UDim2.fromScale(0, -0.2),
				BackgroundTransparency = 1,
				Text = "Planning Mode - Strategy Only",
				TextColor3 = Color3.fromRGB(150, 150, 180),
				TextSize = 10,
				FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium, Enum.FontStyle.Italic),
			})
			else nil,
	})
end
