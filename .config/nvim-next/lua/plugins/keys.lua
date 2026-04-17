require("mini.bracketed").setup()

require("mini.ai").setup()

local keymap = require("mini.keymap")
local map_multistep = keymap.map_multistep
map_multistep("i", "<Tab>", { "pmenu_next" })
map_multistep("i", "<S-Tab>", { "pmenu_prev" })
map_multistep("i", "<CR>", { "pmenu_accept", "minipairs_cr" })
map_multistep("i", "<BS>", { "minipairs_bs" })

-- local map_combo = keymap.map_combo
-- map_combo({ "n", "x" }, "ll", "g$")
-- map_combo({ "n", "x" }, "hh", "g^")
-- map_combo({ "n", "x" }, "jj", "}")
-- map_combo({ "n", "x" }, "kk", "{")

local miniclue = require("mini.clue")
miniclue.setup({
	triggers = {
		-- Leader triggers
		{ mode = { "n", "x" }, keys = "<Leader>" },

		-- `[` and `]` keys
		{ mode = "n", keys = "[" },
		{ mode = "n", keys = "]" },

		-- Built-in completion
		{ mode = "i", keys = "<C-x>" },

		-- `g` key
		{ mode = { "n", "x" }, keys = "g" },

		-- Marks
		{ mode = { "n", "x" }, keys = "'" },
		{ mode = { "n", "x" }, keys = "`" },

		-- Registers
		{ mode = { "n", "x" }, keys = '"' },
		{ mode = { "i", "c" }, keys = "<C-r>" },

		-- Window commands
		{ mode = "n", keys = "<C-w>" },

		-- `z` key
		{ mode = { "n", "x" }, keys = "z" },
	},

	clues = {
		{ mode = "n", keys = "<Leader>b", desc = "+buffers" },
		{ mode = "n", keys = "<Leader>f", desc = "+find/files" },
		{ mode = "n", keys = "<Leader>p", desc = "+plugin" },
		{ mode = "n", keys = "<Leader>q", desc = "+quit/session" },
		{ mode = "n", keys = "<Leader>t", desc = "+toggle" },
		{ mode = "n", keys = "<Leader>td", desc = "Diagnostics text" },
		{ mode = "n", keys = "<Leader>w", desc = "+window" },
		{ mode = "n", keys = "<Leader>x", desc = "+diagnostics/quickfix" },

		-- Enhance this by adding descriptions for <Leader> mapping groups
		miniclue.gen_clues.square_brackets(),
		miniclue.gen_clues.builtin_completion(),
		miniclue.gen_clues.g(),
		miniclue.gen_clues.marks(),
		miniclue.gen_clues.registers(),
		miniclue.gen_clues.windows(),
		miniclue.gen_clues.z(),
	},

	window = {
		config = {
			width = "auto",
		},
	},
})
