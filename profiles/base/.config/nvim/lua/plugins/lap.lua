return {
  "neovim/nvim-lspconfig",
  opts = {
    inlay_hints = { enabled = false },
  },
  init = function()
    vim.lsp.config("vtsls", {
      settings = {
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
