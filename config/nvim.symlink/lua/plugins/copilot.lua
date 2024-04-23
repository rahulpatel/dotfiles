return {
  'zbirenbaum/copilot.lua',
  dependencies = {
    'hrsh7th/nvim-cmp',
  },
  cmd = 'Copilot',
  event = 'InsertEnter',
  config = function()
    require('copilot').setup {
      suggestion = {
        keymap = {
          accept = '<C-y>',
          next = '<C-n>',
          prev = '<C-p>',
        },
      },
    }

    local cmp = require 'cmp'

    cmp.event:on('menu_opened', function()
      vim.b.copilot_suggestion_hidden = true
    end)

    cmp.event:on('menu_closed', function()
      vim.b.copilot_suggestion_hidden = false
    end)
  end,
}
