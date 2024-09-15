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
  --     styles = {
  --       italic = false,
  --     },
  --   }
  --   vim.cmd.colorscheme 'rose-pine-moon'
  -- end,
  -- 'folke/tokyonight.nvim',
  -- lazy = false,
  -- priority = 1000,
  -- opts = {},
  -- init = function()
  --   require('tokyonight').setup {
  --     style = 'storm',
  --   }
  --   vim.cmd.colorscheme 'tokyonight'
  -- end,
  -- 'p00f/alabaster.nvim',
  -- name = 'alabaster',
  -- priority = 1000,
  -- init = function()
  --   vim.cmd.colorscheme 'alabaster'
  -- end,
}
