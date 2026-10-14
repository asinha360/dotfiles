vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

require('config.options')
require('config.keymaps')
require('config.autocmds')
require('config.statusline')

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    'git', 'clone', '--filter=blob:none', '--branch=stable',
    'https://github.com/folke/lazy.nvim.git', lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { 'Failed to clone lazy.nvim:\n' .. out, 'ErrorMsg' } }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  spec = { { import = 'plugins' } },
  install = { colorscheme = { 'monolith' } },
  change_detection = { enabled = false },
  rocks = { enabled = false },
  performance = {
    rtp = { disabled_plugins = { 'gzip', 'netrwPlugin', 'tarPlugin', 'tohtml', 'tutor', 'zipPlugin' } },
  },
})

vim.cmd.colorscheme('monolith')
require('config.lsp')
