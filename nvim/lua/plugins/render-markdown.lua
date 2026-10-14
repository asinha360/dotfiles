return {
  'MeanderingProgrammer/render-markdown.nvim',
  ft = 'markdown',
  opts = {
    -- snacks.image typesets math; render-markdown only draws structure.
    latex = { enabled = false },
    html = { enabled = false },
    win_options = { conceallevel = { rendered = 2 } },
    sign = { enabled = false },
    heading = {
      icons = { '◆ ', '◇ ', '· ', '· ', '· ', '· ' },
      position = 'inline',
      backgrounds = {},
      sign = false,
    },
    bullet = { icons = { '•' } },
    code = { style = 'full', border = 'hide', sign = false },
  },
}
