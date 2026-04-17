require("mini.diff").setup({
	view = {
		style = "sign",
		signs = { add = "▒", change = "▒", delete = "▒" },
		priority = 199,
	},
})

require("mini.git").setup()
-- Use only HEAD name as summary string
local format_summary = function(data)
	-- Utilize buffer-local table summary
	local summary = vim.b[data.buf].minigit_summary
	vim.b[data.buf].minigit_summary_string = summary.head_name or ""
end

local au_opts = { pattern = "MiniGitUpdated", callback = format_summary }
vim.api.nvim_create_autocmd("User", au_opts)
