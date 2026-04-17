vim.pack.add({ "https://github.com/stevearc/oil.nvim" })

require("oil").setup({
	view_options = {
		show_hidden = true,
	},
	skip_confirm_for_simple_edits = true,
	watch_for_changes = true,
	win_options = {
		signcolumn = "yes",
	},
})

vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Oil" })
