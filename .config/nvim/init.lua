-- vim.opt.autocomplete = true
vim.opt.autoread = true
vim.opt.autoindent = true
vim.opt.breakindent = true
vim.opt.confirm = true
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.ignorecase = true
vim.opt.inccommand = "split"
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 999
vim.opt.shiftwidth = 2
vim.opt.showmode = false
vim.opt.signcolumn = "yes"
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.swapfile = false
vim.opt.termguicolors = true
vim.opt.timeoutlen = 300
vim.opt.undofile = true
vim.opt.updatetime = 250
vim.opt.wrap = false

vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>xq", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
vim.keymap.set("n", "<leader>bd", "<cmd>bd<CR>", { desc = "[B]uffer [D]elete" })
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

vim.pack.add({
	{ src = "https://github.com/echasnovski/mini.icons" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/echasnovski/mini.statusline" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/mason-org/mason.nvim" },
	{ src = "https://github.com/folke/snacks.nvim" },
	{ src = "https://github.com/echasnovski/mini.surround" },
	{ src = "https://github.com/echasnovski/mini.move" },
	{ src = "https://github.com/echasnovski/mini.clue" },
	{ src = "https://github.com/folke/tokyonight.nvim" },
})

require("mini.icons").setup()
require("oil").setup({
	win_options = {
		signcolumn = "yes",
	},
	watch_for_changes = true,
	view_options = {
		show_hidden = true,
	},
})
vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

require("mini.statusline").setup()

require("nvim-treesitter").setup()
require("mason").setup()

vim.lsp.enable({ "luals", "vtsls" })

require('snacks').setup({
    bigfile = { enabled = true },
    dashboard = { enabled = false },
    explorer = { enabled = false },
    indent = { enabled = true },
    input = { enabled = false },
    notifier = { enabled = false },
    picker = {
      enabled = true,
      source = {
        files = {
          hidden = true
        }
      }
    },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
})
vim.keymap.set("n", "<leader><leader>", function() Snacks.picker.smart({ hidden = true }) end, { desc = "Smart Find Files" })
vim.keymap.set("n", "<leader>ff", function() Snacks.picker.git_files() end, { desc = "[F]ind git [f]iles" })
vim.keymap.set("n", "<leader>fF", function() Snacks.picker.files({ hidden = true }) end, { desc = "[F]ind all [F]iles" })
vim.keymap.set("n", "<leader>sg", function() Snacks.picker.grep() end, { desc = "[S]earch [G]rep" })
vim.keymap.set("n", "<leader>sr", function() Snacks.picker.resume() end, { desc = "[S]earch [R]esume" })
vim.keymap.set({"n", "x"}, "<leader>sw", function() Snacks.picker.grep_word() end, { desc = "[S]earch [W]ord" })



require("mini.surround").setup()
require("mini.move").setup()

local miniclue = require("mini.clue")
miniclue.setup({
	triggers = {
		-- Leader triggers
		{ mode = "n", keys = "<Leader>" },
		{ mode = "x", keys = "<Leader>" },

		-- Built-in completion
		{ mode = "i", keys = "<C-x>" },

		-- `g` key
		{ mode = "n", keys = "g" },
		{ mode = "x", keys = "g" },

		-- Marks
		{ mode = "n", keys = "'" },
		{ mode = "n", keys = "`" },
		{ mode = "x", keys = "'" },
		{ mode = "x", keys = "`" },

		-- Registers
		{ mode = "n", keys = '"' },
		{ mode = "x", keys = '"' },
		{ mode = "i", keys = "<C-r>" },
		{ mode = "c", keys = "<C-r>" },

		-- Window commands
		{ mode = "n", keys = "<C-w>" },

		-- `z` key
		{ mode = "n", keys = "z" },
		{ mode = "x", keys = "z" },
	},

	clues = {
		-- Enhance this by adding descriptions for <Leader> mapping groups
		miniclue.gen_clues.builtin_completion(),
		miniclue.gen_clues.g(),
		miniclue.gen_clues.marks(),
		miniclue.gen_clues.registers(),
		miniclue.gen_clues.windows(),
		miniclue.gen_clues.z(),
	},
})

require("tokyonight").setup({
	style = "night",
	styles = {
		comments = {},
		keywords = {},
		functions = {},
		variables = {},
	},
	plugins = {
		all = true,
		auto = true,
	},
})
vim.cmd("colorscheme tokyonight-night")
