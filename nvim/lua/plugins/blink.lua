-- Not lazy: blink registers its LSP capabilities when it loads, before clangd starts.
return {
  'saghen/blink.cmp',
  version = '1.*',
  lazy = false,
  dependencies = { 'L3MON4D3/LuaSnip' },
  opts = {
    keymap = { preset = 'default' },
    appearance = { nerd_font_variant = 'mono' },
    snippets = { preset = 'luasnip' },
    sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
    completion = {
      menu = { border = 'rounded' },
      documentation = { auto_show = true, window = { border = 'rounded' } },
    },
    signature = { enabled = true, window = { border = 'rounded' } },
    fuzzy = { implementation = 'prefer_rust_with_warning' },
  },
}
