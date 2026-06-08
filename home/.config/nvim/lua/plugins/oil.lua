return {
  "stevearc/oil.nvim",
  dependencies = { { "nvim-mini/mini.icons", opts = {} } },
  lazy = false,
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    view_options = {
      show_hidden = true,
    },
    skip_confirm_for_simple_edits = true,
    watch_for_changes = true,
    win_options = {
      signcolumn = "yes",
    },
  },
  keys = {
    { "-", "<CMD>Oil<CR>" },
  },
}
