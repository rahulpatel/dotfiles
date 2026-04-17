vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter" })

local treesitter = require("nvim-treesitter")

local languages = {
	"bash",
	"css",
	"diff",
	"html",
	"javascript",
	"jsdoc",
	"json",
	"jsonc",
	"lua",
	"luadoc",
	"markdown",
	"markdown_inline",
	"query",
	"regex",
	"toml",
	"tsx",
	"typescript",
	"vim",
	"vimdoc",
	"yaml",
}

local available = {}
for _, lang in ipairs(treesitter.get_available()) do
	available[lang] = true
end

local installed = {}
for _, lang in ipairs(treesitter.get_installed("parsers")) do
	installed[lang] = true
end

local installing = {}
local waiting = {}

local function enable(buf, lang)
	pcall(vim.treesitter.start, buf, lang)

	if vim.api.nvim_get_current_buf() == buf then
		vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
	else
		vim.api.nvim_set_option_value("foldexpr", "v:lua.vim.treesitter.foldexpr()", {
			scope = "local",
			win = vim.fn.bufwinid(buf),
		})
	end

	if vim.bo[buf].buftype == "" then
		vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end
end

local function flush_waiting(lang)
	local bufs = waiting[lang]
	waiting[lang] = nil

	if not bufs then
		return
	end

	for buf in pairs(bufs) do
		if vim.api.nvim_buf_is_valid(buf) then
			local current_lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
			if current_lang == lang then
				enable(buf, lang)
			end
		end
	end
end

local function install(lang)
	installing[lang] = true

	treesitter.install({ lang }):await(function(err, ok)
		installing[lang] = nil

		if err or ok == false then
			vim.schedule(function()
				vim.notify(string.format("Tree-sitter install failed for %s", lang), vim.log.levels.WARN)
			end)
			return
		end

		installed[lang] = true

		vim.schedule(function()
			flush_waiting(lang)
		end)
	end)
end

local startup_languages = vim.tbl_filter(function(lang)
	return available[lang] and not installed[lang]
end, languages)

if #startup_languages > 0 then
	for _, lang in ipairs(startup_languages) do
		install(lang)
	end
end

vim.api.nvim_create_autocmd("FileType", {
	callback = function(args)
		local buf = args.buf
		local ft = vim.bo[buf].filetype
		local lang = vim.treesitter.language.get_lang(ft)

		if not lang or not available[lang] then
			return
		end

		if installed[lang] then
			enable(buf, lang)
			return
		end

		waiting[lang] = waiting[lang] or {}
		waiting[lang][buf] = true

		if installing[lang] then
			return
		end

		install(lang)
	end,
})
