return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false,
  build = ':TSUpdate',
  config = function()
    require('nvim-treesitter').install({
      'markdown', 'markdown_inline', 'latex', 'lua', 'cpp', 'python', 'yaml', 'bash',
    })
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('monolith.treesitter', { clear = true }),
      callback = function(ev)
        pcall(vim.treesitter.start, ev.buf)
      end,
    })
  end,
}
