--[[
	ColorUtils.luau
	
	Utilities for color calculations, primarily used for ensuring
	readability through contrast.
]]

local ColorUtils = {}

-- Returns the perceived brightness of a color (0 to 1)
-- Uses the YIQ formula which is more accurate for human perception
function ColorUtils.getBrightness(color: Color3): number
	return (color.R * 299 + color.G * 587 + color.B * 114) / 1000
end

-- Returns either White or Black depending on which provides better contrast
function ColorUtils.getContrastColor(color: Color3): Color3
	local brightness = ColorUtils.getBrightness(color)
	return if brightness > 0.5 then Color3.new(0, 0, 0) else Color3.new(1, 1, 1)
end

return ColorUtils
