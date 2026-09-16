-- ============================================================================
-- Mode configuration
-- ============================================================================

return {
	default_mode = "writing",

	-- ------------------------------------------------------------------------
	-- Monitor roles
	-- ------------------------------------------------------------------------
	--
	-- Thứ tự ưu tiên.
	--
	-- Hiện tại laptop của bạn có eDP-1 nên tạm dùng nó làm primary.
	-- Khi tới cơ quan, chạy:
	--
	--     hyprctl monitors
	--
	-- rồi thêm tên monitor ngoài vào đây.
	--
	monitors = {
		preferred_primary = {
			"eDP-1",
		},

		preferred_secondary = {},
	},

	-- ------------------------------------------------------------------------
	-- Modes
	-- ------------------------------------------------------------------------

	modes = {
		writing = {
			name = "Writing",
			icon = "󰈙",
			key = "1",

			lanes = {
				primary = "mode-writing-primary",
				secondary = "mode-writing-secondary",
			},
		},

		code = {
			name = "Code",
			icon = "",
			key = "2",

			lanes = {
				primary = "mode-code-primary",
				secondary = "mode-code-secondary",
			},
		},

		relax = {
			name = "Relax",
			icon = "",
			key = "3",

			lanes = {
				primary = "mode-relax-primary",
				secondary = "mode-relax-secondary",
			},
		},
	},
}
