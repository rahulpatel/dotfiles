return {
  "p00f/alabaster.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    vim.opt.background = "dark"
    vim.cmd([[colorscheme alabaster]])
  end,
}
