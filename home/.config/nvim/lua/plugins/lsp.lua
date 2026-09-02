return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      vtsls = {
        settings = {
          javascript = {
            preferences = {
              autoImportFileExcludePatterns = { "repos/**" },
            },
          },
          typescript = {
            preferences = {
              autoImportFileExcludePatterns = { "repos/**" },
            },
          },
        },
      },
    },
  },
}
