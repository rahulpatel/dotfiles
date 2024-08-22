return {
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1000,
  init = function()
    vim.cmd.colorscheme 'catppuccin-frappe'
  end,
  -- 'rose-pine/neovim',
  -- priority = 1000,
  -- init = function()
  --   require('rose-pine').setup {
  --     variant = 'moon',
  --   }
  --   vim.cmd.colorscheme 'rose-pine-moon'
  -- end,
}
