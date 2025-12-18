--[[
	PlayerRack.luau
	
	Shows the player's 7 letter tiles. Players can click tiles to select them
	for placement on the board. All tile movements are smoothly animated.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)
local LetterTile = require(ReplicatedStorage.UI.components.game.LetterTile)

local e = React.createElement

local ANIMATION_DURATION = 0.25
local MAX_TILES = 7

export type PlayerRackProps = {
	Letters: { string }, -- Array of up to 7 letters
	SelectedIndex: number?, -- Currently selected tile index
	DraggingIndex: number?, -- Index of tile being dragged
	IsDragging: boolean?, -- Is any tile currently being dragged
	IsDisabled: boolean?, -- Disable interactions (not your turn)
	IsExchangeMode: boolean?, -- In exchange tile selection mode
	ExchangeSelection: { [number]: boolean }?, -- Which tiles are selected for exchange
	OnTileClick: ((index: number, letter: string) -> ())?,
	OnDragStart: ((index: number, letter: string) -> ())?,
	OnDropToRack: (() -> ())?, -- Called when a tile is dropped back to rack
	OnExchangeToggle: ((rackIndex: number) -> ())?, -- Toggle tile for exchange
}

-- Animated tile wrapper component
local function AnimatedTile(tileProps: {
	Letter: string,
	Index: number,
	TotalTiles: number,
	TargetX: number,
	IsSelected: boolean?,
	IsDragging: boolean?,
	IsDisabled: boolean?,
	IsNew: boolean?,
	OnClick: ((number, string) -> ())?,
	OnDragStart: ((number, string) -> ())?,
})
	local tileWidth = 1 / MAX_TILES
	local targetX = tileProps.TargetX
	
	-- Animated position state - start at target unless new
	local currentX, setCurrentX = React.useState(if tileProps.IsNew then 1.2 else targetX)
	local currentScale, setCurrentScale = React.useState(if tileProps.IsNew then 0.5 else 1)
	local animConnection = React.useRef(nil)
	
	-- Animate to target position whenever it changes
	React.useEffect(function()
		-- Always cancel existing animation when targetX changes
		if animConnection.current then
			animConnection.current:Disconnect()
			animConnection.current = nil
		end
		
		local needsAnimation = math.abs(currentX - targetX) > 0.005 or math.abs(currentScale - 1) > 0.01
		
		if needsAnimation then
			local startXVal = currentX
			local startScaleVal = currentScale
			local startTime = tick()
			
			animConnection.current = RunService.Heartbeat:Connect(function()
				local elapsed = tick() - startTime
				local alpha = math.min(elapsed / ANIMATION_DURATION, 1)
				
				-- Smooth ease-out cubic
				local easedAlpha = 1 - math.pow(1 - alpha, 3)
				
				local newX = startXVal + (targetX - startXVal) * easedAlpha
				local newScale = startScaleVal + (1 - startScaleVal) * easedAlpha
				
				setCurrentX(newX)
				setCurrentScale(newScale)
				
				if alpha >= 1 then
					setCurrentX(targetX)
					setCurrentScale(1)
					if animConnection.current then
						animConnection.current:Disconnect()
						animConnection.current = nil
					end
				end
			end)
		else
			-- Snap to target if very close
			setCurrentX(targetX)
			setCurrentScale(1)
		end
		
		return function()
			if animConnection.current then
				animConnection.current:Disconnect()
				animConnection.current = nil
			end
		end
	end, { targetX })
	
	return e("Frame", {
		Size = UDim2.fromScale(tileWidth * currentScale, currentScale),
		Position = UDim2.fromScale(currentX, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		ZIndex = if tileProps.IsDragging then 10 else 1,
	}, {
		Content = e(LetterTile, {
			Letter = tileProps.Letter,
			Index = tileProps.Index,
			IsSelected = tileProps.IsSelected,
			IsDragging = tileProps.IsDragging,
			IsDisabled = tileProps.IsDisabled,
			IsNew = false,
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
	local isDragging = props.IsDragging
	local isDisabled = props.IsDisabled
	local isExchangeMode = props.IsExchangeMode
	local exchangeSelection = props.ExchangeSelection or {}
	local isHoveringRack, setIsHoveringRack = React.useState(false)
	
	-- Track previous rack size to detect new tiles
	local prevRackSize = React.useRef(#letters)
	local newTileIndices, setNewTileIndices = React.useState({} :: {[number]: boolean})
	
	-- Detect new tiles
	React.useEffect(function()
		local currentSize = #letters
		local prevSize = prevRackSize.current
		
		if currentSize > prevSize and prevSize > 0 then
			local newFlags = {}
			for i = prevSize + 1, currentSize do
				newFlags[i] = true
			end
			setNewTileIndices(newFlags)
			
			task.delay(0.5, function()
				setNewTileIndices({})
			end)
		end
		
		prevRackSize.current = currentSize
	end, { letters })
	
	-- Calculate target positions for centered layout
	local tileWidth = 1 / MAX_TILES
	local totalWidth = #letters * tileWidth
	local startX = (1 - totalWidth) / 2
	
	local tiles = {}
	for i, letter in ipairs(letters) do
		local isSelectedForExchange = exchangeSelection[i] == true
		local isNewTile = newTileIndices[i] == true
		local targetX = startX + (i - 1) * tileWidth + tileWidth / 2
		
		local function handleExchangeClick(index: number, _letter: string)
			if props.OnExchangeToggle then
				props.OnExchangeToggle(index)
			end
		end
		
		-- Use index as key for stable component identity
		tiles["Tile_" .. i] = e(AnimatedTile, {
			Letter = letter,
			Index = i,
			TotalTiles = #letters,
			TargetX = targetX,
			IsSelected = if isExchangeMode then isSelectedForExchange else (selectedIndex == i),
			IsDragging = draggingIndex == i,
			IsDisabled = isDisabled,
			IsNew = isNewTile,
			OnClick = if isExchangeMode then handleExchangeClick else props.OnTileClick,
			OnDragStart = if isExchangeMode then nil else props.OnDragStart,
		})
	end
	
	-- Show highlight when a tile can be dropped here
	local rackBgColor = Color3.fromRGB(35, 55, 100)
	local strokeColor = Color3.fromRGB(70, 100, 160)
	if isDragging and isHoveringRack then
		rackBgColor = Color3.fromRGB(60, 80, 140) -- Brighter blue highlight for drop zone
		strokeColor = Color3.fromRGB(249, 0, 149) -- Pink stroke
	end
	
	return e("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = rackBgColor,
		ClipsDescendants = false, -- Allow tiles to animate in from outside
		Text = "",
		AutoButtonColor = false,
		[React.Event.MouseEnter] = function()
			setIsHoveringRack(true)
		end,
		[React.Event.MouseLeave] = function()
			setIsHoveringRack(false)
		end,
		[React.Event.MouseButton1Up] = function()
			if isDragging and props.OnDropToRack then
				props.OnDropToRack()
			end
		end,
	}, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0.1, 0),
		}),
		
		UIStroke = e("UIStroke", {
			Color = strokeColor,
			Thickness = 3,
		}),
		
		-- Bright blue gradient
		UIGradient = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 75, 130)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 65, 115)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 50, 95)),
			}),
			Rotation = 90,
		}),
		
		UIPadding = e("UIPadding", {
			PaddingBottom = UDim.new(0.05, 0),
			PaddingTop = UDim.new(0.05, 0),
			PaddingLeft = UDim.new(0.02, 0),
			PaddingRight = UDim.new(0.02, 0),
		}),
		
		TileContainer = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ClipsDescendants = false,
		}, tiles),
		
		-- Strategy indicator (Optional: Could add a subtle text saying "Planning Mode")
		StrategyHint = isDisabled and e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 15),
			Position = UDim2.new(0, 0, 0, -18),
			BackgroundTransparency = 1,
			Text = "Planning Mode - Strategy Only",
			TextColor3 = Color3.fromRGB(150, 150, 180),
			TextSize = 10,
			FontFace = Font.new("rbxassetid://11702779517", Enum.FontWeight.Medium, Enum.FontStyle.Italic),
		}) or nil,
	})
end

