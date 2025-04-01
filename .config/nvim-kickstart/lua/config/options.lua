-- Leader
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- UI
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.showmode = false
vim.opt.breakindent = true
vim.opt.signcolumn = 'yes'
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = 'split'
vim.opt.cursorline = true
vim.opt.scrolloff = 999

-- UX
vim.opt.mouse = 'a'
vim.opt.undofile = true
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.confirm = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Diagnostic Config
-- See :help vim.diagnostic.Opts
vim.diagnostic.config({
  virtual_lines = {
    current_line = true,
  },
  -- severity_sort = true,
  -- float = { border = 'rounded', source = 'if_many' },
  -- underline = { severity = vim.diagnostic.severity.ERROR },
  -- signs = {
  --   text = {
  --     [vim.diagnostic.severity.ERROR] = '󰅚 ',
  --     [vim.diagnostic.severity.WARN] = '󰀪 ',
  --     [vim.diagnostic.severity.INFO] = '󰋽 ',
  --     [vim.diagnostic.severity.HINT] = '󰌶 ',
  --   },
  -- },
  -- virtual_text = {
  --   source = 'if_many',
  --   spacing = 2,
  --   format = function(diagnostic)
  --     local diagnostic_message = {
  --       [vim.diagnostic.severity.ERROR] = diagnostic.message,
  --       [vim.diagnostic.severity.WARN] = diagnostic.message,
  --       [vim.diagnostic.severity.INFO] = diagnostic.message,
  --       [vim.diagnostic.severity.HINT] = diagnostic.message,
  --     }
  --     return diagnostic_message[diagnostic.severity]
  --   end,
  -- },
})
