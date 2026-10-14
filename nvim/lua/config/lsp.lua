if vim.fn.executable('clangd') == 1 then
  vim.lsp.config('clangd', {
    cmd = { 'clangd', '--background-index', '--log=error' },
    filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
    root_markers = { 'compile_commands.json', 'compile_flags.txt', '.clangd', '.git' },
  })
  vim.lsp.enable('clangd')
end
