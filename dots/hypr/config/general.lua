-- How Hyprland work?
-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/

hl.config({
	general = {
		gaps_in = 4,
		gaps_out = 4,

		border_size = 2,

		col = {
			active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
			inactive_border = "rgba(595959aa)",
		},

		-- Set to true to enable resizing windows by clicking and dragging on borders and gaps
		resize_on_border = false,

		-- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
		allow_tearing = false,

		layout = "dwindle",
	},

	dwindle = {
		preserve_split = true,
	},

	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,

		focus_on_activate = true,
	},

	cursor = {
		no_warps = false,
	},
	-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
	master = {
		new_status = "master",
	},
	-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
	scrolling = {
		fullscreen_on_one_column = true,
	},
})

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
