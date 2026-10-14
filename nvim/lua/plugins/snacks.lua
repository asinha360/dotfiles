return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  -- Inside tmux, snacks.image runs `tmux set -p allow-passthrough all` on the current pane
  -- (image/terminal.lua, in both the tmux env setup and the terminal detection). It is
  -- hard-coded upstream and harmless next to the global `allow-passthrough on` in
  -- tmux/monolith.conf, so it is left alone. Headless tests must unset TMUX and use
  -- TERM=xterm-256color so it never fires.
  opts = {
    image = {
      enabled = true,
      doc = { enabled = true, inline = true, float = true },
      img_dirs = { '_attachments', 'attachments', 'img', 'images', 'assets' },
      convert = { notify = false },
      math = {
        enabled = true,
        latex = {
          font_size = 'Large',
          packages = { 'amsmath', 'amssymb', 'mathtools' },
          -- Default snacks template plus STIX Two, which must load before the packages line.
          -- An explicit varwidth keeps long display math from being clipped at \linewidth.
          tpl = [[
            \documentclass[preview,border=0pt,varwidth=40cm,12pt]{standalone}
            \usepackage{stix2}
            \usepackage{${packages}}
            \begin{document}
            ${header}
            { \${font_size} \selectfont
              \color[HTML]{${color}}
            ${content}}
            \end{document}]],
        },
      },
    },
    picker = { enabled = true },
    explorer = { enabled = true },
    notifier = { enabled = true, style = 'minimal' },
  },
}
