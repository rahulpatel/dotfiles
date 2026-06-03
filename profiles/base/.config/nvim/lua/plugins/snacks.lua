return {
  "folke/snacks.nvim",
  ---@type snacks.Config
  opts = {
    picker = {
      sources = {
        explorer = {
          enabled = false,
          hidden = true,
        },
        files = {
          cmd = "fd",
          hidden = true,
        },
        grep = {
          hidden = true,
        },
      },
    },
  },
}
