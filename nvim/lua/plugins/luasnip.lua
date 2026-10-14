return {
  'L3MON4D3/LuaSnip',
  version = 'v2.*',
  build = 'make install_jsregexp',
  lazy = true,
  dependencies = { 'iurimateus/luasnip-latex-snippets.nvim' },
  config = function()
    local ls = require('luasnip')
    ls.config.setup({ enable_autosnippets = true, store_selection_keys = '<Tab>' })
    require('luasnip-latex-snippets').setup({ use_treesitter = true })
    -- Upstream's markdown mk/dm also fire inside code blocks (`mkdir`); drop them
    -- in favour of the versions in snippets/markdown.lua. Runs after upstream's
    -- own once-per-session FileType hook because it is registered later.
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'markdown',
      once = true,
      callback = function()
        for _, snip in ipairs(ls.get_snippets('markdown', { type = 'autosnippets' })) do
          if (snip.trigger == 'mk' or snip.trigger == 'dm') and snip.effective_priority < 1000 then
            snip:invalidate()
          end
        end
      end,
    })
    require('luasnip.loaders.from_lua').lazy_load({ paths = { vim.fn.stdpath('config') .. '/snippets' } })
  end,
}
