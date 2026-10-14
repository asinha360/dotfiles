local map = vim.keymap.set

map('n', '<Esc>', '<cmd>nohlsearch<cr>')

-- snacks
map('n', '<leader><space>', function() Snacks.picker.smart() end, { desc = 'Smart find' })
map('n', '<leader>ff', function() Snacks.picker.files() end, { desc = 'Files' })
map('n', '<leader>fg', function() Snacks.picker.grep() end, { desc = 'Grep' })
map('n', '<leader>fb', function() Snacks.picker.buffers() end, { desc = 'Buffers' })
map('n', '<leader>e', function() Snacks.explorer() end, { desc = 'Explorer' })
map('n', '<leader>m', function() Snacks.image.hover() end, { desc = 'Show image/math under cursor' })

-- obsidian (vault)
map('n', '<leader>on', '<cmd>Obsidian new<cr>', { desc = 'New note' })
map('n', '<leader>od', '<cmd>Obsidian today<cr>', { desc = 'Daily note' })
map('n', '<leader>os', '<cmd>Obsidian search<cr>', { desc = 'Search vault' })
map('n', '<leader>oo', '<cmd>Obsidian quick_switch<cr>', { desc = 'Switch note' })
map('n', '<leader>ob', '<cmd>Obsidian backlinks<cr>', { desc = 'Backlinks' })
map('n', '<leader>ot', '<cmd>Obsidian template<cr>', { desc = 'Insert template' })

-- diagnostics
map('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Line diagnostics' })
