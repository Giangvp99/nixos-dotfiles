local map = vim.keymap.set

-- Telescope

local telescope = require("telescope")

telescope.setup({
	defaults = {
		layout_strategy = "horizontal",

		layout_config = {
			horizontal = {
				preview_width = 0.55,
			},

			width = 0.90,
			height = 0.85,
		},

		sorting_strategy = "ascending",
		prompt_prefix = "  ",
		selection_caret = "➜ ",
	},
})

pcall(telescope.load_extension, "fzf")
pcall(telescope.load_extension, "file_browser")

local builtin = require("telescope.builtin")

map("n", "<leader>ff", builtin.find_files, {
	desc = "Tìm tệp",
})

map("n", "<leader>fg", builtin.live_grep, {
	desc = "Tìm nội dung",
})

map("n", "<leader>fb", builtin.buffers, {
	desc = "Tìm buffer",
})

map("n", "<leader>fh", builtin.help_tags, {
	desc = "Tìm trợ giúp",
})

map("n", "<leader>fr", builtin.oldfiles, {
	desc = "Tệp đã mở",
})

map("n", "<leader>fc", builtin.commands, {
	desc = "Tìm lệnh",
})

map("n", "<leader>fk", builtin.keymaps, {
	desc = "Tìm phím tắt",
})

map("n", "<leader>fd", builtin.diagnostics, {
	desc = "Tìm chẩn đoán",
})

-- Neo-tree

require("neo-tree").setup({
	close_if_last_window = true,
	enable_git_status = true,
	enable_diagnostics = true,

	filesystem = {
		filtered_items = {
			visible = false,
			hide_dotfiles = false,
			hide_gitignored = true,
		},

		follow_current_file = {
			enabled = true,
		},

		use_libuv_file_watcher = true,
	},

	window = {
		width = 28,
	},
})

map("n", "<leader>e", "<cmd>Neotree toggle<cr>", {
	desc = "Bật/tắt cây thư mục",
})

map("n", "<leader>E", "<cmd>Neotree reveal<cr>", {
	desc = "Hiện tệp hiện tại trong cây",
})
