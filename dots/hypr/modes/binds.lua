-- ============================================================================
-- Mode keybindings
-- ============================================================================

local Config = require("modes.config")

local Mode = require("modes.core")

-- ============================================================================
-- Mode selection
-- ============================================================================

for mode_id, mode in pairs(Config.modes) do
	hl.bind("SUPER + " .. mode.key, function()
		Mode.switch(mode_id)
	end, {
		description = "Switch to " .. mode.name .. " mode",
	})
end

-- ============================================================================
-- Navigate apps inside current lane
-- ============================================================================

hl.bind("SUPER + H", function()
	Mode.focus_app("l")
end, {
	description = "Previous app",
})

hl.bind("SUPER + L", function()
	Mode.focus_app("r")
end, {
	description = "Next app",
})

-- ============================================================================
-- Reorder apps
-- ============================================================================

hl.bind("SUPER + SHIFT + H", function()
	Mode.swap_app("l")
end, {
	description = "Move app left",
})

hl.bind("SUPER + SHIFT + L", function()
	Mode.swap_app("r")
end, {
	description = "Move app right",
})

-- ============================================================================
-- Move focus between physical monitors
-- ============================================================================

hl.bind("SUPER + CTRL + H", function()
	Mode.focus_monitor("l")
end, {
	description = "Focus monitor left",
})

hl.bind("SUPER + CTRL + L", function()
	Mode.focus_monitor("r")
end, {
	description = "Focus monitor right",
})

-- ============================================================================
-- Reflow current mode
-- ============================================================================

hl.bind("SUPER + CTRL + R", function()
	Mode.refresh()
end, {
	description = "Refresh current mode topology",
})
