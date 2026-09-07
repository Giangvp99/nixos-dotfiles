local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Cursor
opt.cursorline = true
opt.colorcolumn = "100"

-- Sign column
opt.signcolumn = "yes"
opt.numberwidth = 4

-- Indentation
opt.expandtab = true
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.smartindent = true
opt.breakindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Display
opt.wrap = false
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.termguicolors = true
opt.showmode = false

-- Splits
opt.splitbelow = true
opt.splitright = true

-- Mouse / clipboard
opt.mouse = "a"
opt.clipboard = "unnamedplus"

-- Completion
opt.completeopt = {
	"menu",
	"menuone",
	"noselect",
}

-- Files
opt.swapfile = false
opt.backup = false
opt.undofile = true

-- Performance
opt.updatetime = 250
opt.timeoutlen = 400

-- Editing
opt.confirm = true
opt.inccommand = "split"

-- Folding
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true
