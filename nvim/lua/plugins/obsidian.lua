return {
  'obsidian-nvim/obsidian.nvim',
  version = '*',
  ft = 'markdown',
  -- Without the vault obsidian.nvim errors on every markdown file (it needs a workspace).
  cond = function()
    return vim.uv.fs_stat(vim.fn.expand('~/projects/study-vault')) ~= nil
  end,
  cmd = 'Obsidian',
  opts = {
    legacy_commands = false,
    workspaces = { { name = 'study', path = '~/projects/study-vault' } },
    note_id_func = function(title, dir)
      return require('obsidian.builtin').title_id(title, dir)
    end,
    note = { template = 'note.md' },
    templates = { folder = 'templates' },
    daily_notes = { folder = 'daily', template = 'daily.md', default_tags = {} },
    attachments = { folder = '_attachments' },
    picker = { name = 'snacks.picker' },
    ui = { enable = false },
    footer = { enabled = false },
    -- Never rewrite frontmatter on save. New notes get theirs from templates/note.md.
    frontmatter = { enabled = false },
  },
}
