local o = vim.opt

o.termguicolors = true
o.shortmess:append('I')
o.laststatus = 3
o.cmdheight = 1
o.showmode = false
o.signcolumn = 'auto'
o.number = true
o.cursorline = true
-- The default ends in TermCursor, which makes nvim emit OSC 112 (reset cursor colour) in
-- terminal mode; wallsync owns the cursor colour and Ghostty breaks on that reset.
o.guicursor = 'n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,t:block-blinkon500-blinkoff500'
o.scrolloff = 6
o.fillchars = { eob = ' ' }
o.winborder = 'rounded'
-- The window title becomes the tmux pane title, shown on the panel's top border.
o.title = true
o.titlestring = 'nvim · %t'
o.clipboard = 'unnamedplus'
o.undofile = true
o.ignorecase = true
o.smartcase = true
o.splitright = true
o.splitbelow = true
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.updatetime = 250
local add = vim.fn.stdpath('config') .. '/spell/en.utf-8.add'
o.spellfile = add
-- nvim only compiles the word list when it is changed with zg, so build the .spl when missing or stale.
if vim.fn.getftime(add) > vim.fn.getftime(add .. '.spl') then
  vim.cmd('silent! mkspell! ' .. vim.fn.fnameescape(add))
end
o.spelllang = { 'en' }
