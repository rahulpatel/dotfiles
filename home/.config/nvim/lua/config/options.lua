-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Keep agent-only vendored repositories out of built-in file completion and
-- search paths. Dedicated tools can still open files under repos/ directly.
vim.opt.wildignore:append({ "*/repos/*" })
