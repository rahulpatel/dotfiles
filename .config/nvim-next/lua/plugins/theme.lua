vim.pack.add({ { src = "https://github.com/catppuccin/nvim", name = "catppuccin" } })

require("catppuccin").setup({
	flavour = "mocha",
	integrations = {
		mini = {
			enable = true,
		},
	},
})

vim.cmd.colorscheme("catppuccin")
