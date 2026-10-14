-- Board A statusline: ' NORMAL ' block, file name, then 'filetype · L:C · P%' on the right.
local M = {}

local modes = {
  n = 'NORMAL', no = 'O-PENDING', v = 'VISUAL', V = 'V-LINE', ['\22'] = 'V-BLOCK',
  s = 'SELECT', S = 'S-LINE', ['\19'] = 'S-BLOCK', i = 'INSERT', R = 'REPLACE',
  c = 'COMMAND', r = 'PROMPT', ['!'] = 'SHELL', t = 'TERMINAL',
}

function M.render()
  local mode = vim.api.nvim_get_mode().mode
  local name = modes[mode] or modes[mode:sub(1, 2)] or modes[mode:sub(1, 1)] or mode:upper()
  local ft = vim.bo.filetype ~= '' and vim.bo.filetype or 'text'
  return table.concat({
    '%#StatusLineMode# ', name, ' %*',
    '%#StatusLineFile#  %t%m%r',
    '%=',
    '%#StatusLineInfo#', ft, ' · %l:%c · %p%% ',
  })
end

vim.o.statusline = "%!v:lua.require'config.statusline'.render()"

return M
