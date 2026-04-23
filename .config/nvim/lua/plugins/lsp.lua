return {
  "neovim/nvim-lspconfig",
  opts = {
    inlay_hints = { enabled = false },
  },
  init = function()
    vim.lsp.config("vtsls", {
      settings = {
        typescript = { tsserver = { maxTsServerMemory = 8192 } },
        vtsls = {
          autoUseWorkspaceTsdk = true,
          experimental = {
            completion = {
              enableServerSideFuzzyMatch = true,
            },
          },
        },
      },
    })
  end,
}
