local group = vim.api.nvim_create_augroup('monolith', { clear = true })
local function au(event, opts)
  opts.group = group
  vim.api.nvim_create_autocmd(event, opts)
end

-- wallsync's mid hook sends SIGUSR1 after rendering ~/.cache/wallsync/out/nvim.lua.
au('Signal', {
  pattern = 'SIGUSR1',
  callback = function()
    vim.schedule(function()
      vim.cmd.colorscheme('monolith')
    end)
  end,
})

-- snacks bakes SnacksImageMath into the LaTeX source (and so the image cache key)
-- but never refreshes it. Schemes that do not define SnacksImageMath (monolith does)
-- get it from @markup.math.latex; then re-run each inline image updater so math is
-- re-rendered in the new colour.
au('ColorScheme', {
  callback = function()
    local function fg_of(name)
      return vim.api.nvim_get_hl(0, { name = name, link = false }).fg
    end
    if vim.g.colors_name ~= 'monolith' and fg_of('@markup.math.latex') then
      vim.api.nvim_set_hl(0, 'SnacksImageMath', { fg = fg_of('@markup.math.latex') })
    end
    -- Forget which images the terminal holds so they are sent again: a restarted Ghostty has none
    pcall(function() require('snacks.image.image').clear() end)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.b[buf].snacks_image_attached then
        pcall(vim.api.nvim_exec_autocmds, 'BufWinEnter', { group = 'snacks.image.inline.' .. buf, buffer = buf })
      end
    end
  end,
})

-- Notes change underneath us (Obsidian, git, the vault panel).
au({ 'FocusGained', 'BufEnter' }, {
  callback = function()
    if vim.o.buftype ~= 'nofile' then
      vim.cmd.checktime()
    end
  end,
})

au('ModeChanged', { command = 'redrawstatus' })

-- Markdown is prose (wrap, spell, concealed math, no numbers); everything else is code.
au('FileType', {
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= '' then
      return
    end
    local md = ev.match == 'markdown'
    local wo = vim.opt_local
    wo.number = not md
    wo.conceallevel = md and 2 or 0
    wo.wrap = md
    wo.linebreak = md
    wo.breakindent = md
    wo.spell = md
  end,
})
