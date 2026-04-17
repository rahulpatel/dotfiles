require("mini.cursorword").setup()

require("mini.indentscope").setup({
	symbol = "│",
})

require("mini.surround").setup()

require("mini.pairs").setup()

local MiniHipatterns = require("mini.hipatterns")
MiniHipatterns.setup({
	highlighter = {
		-- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
		fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
		hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
		todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
		note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },

		-- Highlight hex color strings (`#rrggbb`) using that color
		hex_color = MiniHipatterns.gen_highlighter.hex_color(),
	},
})
