vim.pack.add({
	"https://github.com/mason-org/mason.nvim",
	"https://github.com/mason-org/mason-lspconfig.nvim",
	"https://github.com/neovim/nvim-lspconfig",
})

local servers = {
	"bashls",
	"biome",
	"cssls",
	"eslint",
	"html",
	"jsonls",
	"lua_ls",
	"marksman",
	"taplo",
	"ts_ls",
	"vimls",
	"yamlls",
}

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = false

require("mason").setup({
	ui = {
		icons = {
			package_installed = "*",
			package_pending = "-",
			package_uninstalled = "o",
		},
	},
})

local function format(buf)
	if not vim.g.autoformat or vim.b[buf].autoformat == false then
		return
	end

	if vim.bo[buf].buftype ~= "" or not vim.bo[buf].modifiable then
		return
	end

	local clients = vim.lsp.get_clients({ bufnr = buf })
	local biome
	local eslint

	for _, client in ipairs(clients) do
		if client.name == "biome" and client:supports_method("textDocument/formatting") then
			biome = client
		elseif client.name == "eslint" then
			eslint = client
		end
	end

	if biome then
		vim.lsp.buf.format({
			async = false,
			bufnr = buf,
			filter = function(client)
				return client.id == biome.id
			end,
			timeout_ms = 3000,
		})
		return
	end

	if eslint then
		if vim.fn.exists(":LspEslintFixAll") == 2 then
			pcall(vim.cmd, "silent LspEslintFixAll")
			return
		end

		if eslint:supports_method("textDocument/formatting") then
			vim.lsp.buf.format({
				async = false,
				bufnr = buf,
				filter = function(client)
					return client.id == eslint.id
				end,
				timeout_ms = 3000,
			})
			return
		end
	end

	if #vim.lsp.get_clients({ bufnr = buf, method = "textDocument/formatting" }) == 0 then
		return
	end

	vim.lsp.buf.format({
		async = false,
		bufnr = buf,
		timeout_ms = 3000,
	})
end

vim.lsp.config("*", {
	capabilities = capabilities,
})

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				checkThirdParty = false,
			},
		},
	},
})

vim.lsp.config("eslint", {
	settings = {
		format = true,
		validate = "on",
	},
})

require("mason-lspconfig").setup({
	ensure_installed = servers,
	automatic_enable = true,
})

vim.api.nvim_create_autocmd("BufWritePre", {
	group = vim.api.nvim_create_augroup("user_lsp_format", { clear = true }),
	callback = function(args)
		format(args.buf)
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(event)
		local map = function(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, {
				buffer = event.buf,
				desc = desc,
			})
		end

		map("n", "gd", vim.lsp.buf.definition, "LSP definition")
		map("n", "gD", vim.lsp.buf.declaration, "LSP declaration")
		map("n", "gr", vim.lsp.buf.references, "LSP references")
		map("n", "gi", vim.lsp.buf.implementation, "LSP implementation")
		map("n", "K", vim.lsp.buf.hover, "LSP hover")
		map("n", "<Leader>cf", function()
			format(event.buf)
		end, "Format buffer")
		map("n", "<Leader>cr", vim.lsp.buf.rename, "LSP rename")
		map({ "n", "x" }, "<Leader>ca", vim.lsp.buf.code_action, "LSP code action")
		map("n", "<Leader>cd", vim.diagnostic.open_float, "Line diagnostics")
	end,
})
