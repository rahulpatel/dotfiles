return {
  'stevearc/oil.nvim',
  lazy = false,
  dependencies = {
    { 'echasnovski/mini.icons', opts = {} },
  },
  keys = {
    { '-', '<CMD>Oil<CR>', desc = 'Open parent directory' },
  },
  config = function()
    require('oil').setup({
      view_options = {
        show_hidden = true,
      },
    })

    vim.api.nvim_create_autocmd('User', {
      pattern = 'OilActionsPost',
      callback = function(event)
        if event.data.actions.type == 'move' then
          Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
        end
      end,
    })
  end,
}
