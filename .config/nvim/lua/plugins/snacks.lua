return {
  "folke/snacks.nvim",
  ---@type snacks.Config
  opts = {
    picker = {
      sources = {
        explorer = { enabled = false },
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
  keys = {
    { "<leader>fe", false },
    { "<leader>fE", false },
    { "<leader>e", false },
    { "<leader>E", false },
  },
}
