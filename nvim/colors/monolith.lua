-- Near-monochrome scheme driven by the wallpaper palette that wallsync renders.
local ok, p = pcall(dofile, vim.fn.expand('~/.cache/wallsync/out/nvim.lua'))
if not ok or type(p) ~= 'table' or type(p.ansi) ~= 'table' then
  -- Golden palette for H=205, C=0.2 (wallsync/sample-palette.json).
  p = {
    H = 205,
    panel = '#121517', solid = '#14171A', line = '#3E4346', lineHi = '#A4A7AA',
    fg = '#D7DCE0', sub = '#ACB4B9', dim = '#808B93', hi = '#EDF0F2', sel = '#30373C',
    ansi = {
      '#1A1F23', '#C39DA8', '#93BDA8', '#BFBB96', '#A6B7C9', '#BEA0C5', '#93B8BD', '#D7DCE0',
      '#808B93', '#D3B6BE', '#ADCDBD', '#CFCCB0', '#C0CCD8', '#CFB9D5', '#ADC9CD', '#EDF0F2',
    },
  }
end

vim.cmd('highlight clear')
if vim.o.background ~= 'dark' then
  vim.o.background = 'dark'
end
vim.g.colors_name = 'monolith'

local a = p.ansi
local red, green, yellow, blue, cyan = a[2], a[3], a[4], a[5], a[7]

local groups = {
  -- Editor; Normal has no background so Ghostty's translucency shows through.
  Normal = { fg = p.fg },
  NormalFloat = { fg = p.fg, bg = p.solid },
  FloatBorder = { fg = p.line, bg = p.solid },
  FloatTitle = { fg = p.hi, bg = p.solid, bold = true },
  FloatFooter = { fg = p.dim, bg = p.solid },
  Cursor = { fg = p.solid, bg = p.hi },
  CursorLine = { bg = p.sel },
  CursorColumn = { bg = p.sel },
  ColorColumn = { bg = a[1] },
  Visual = { bg = p.sel },
  LineNr = { fg = p.dim },
  CursorLineNr = { fg = p.hi, bold = true },
  SignColumn = {},
  FoldColumn = { fg = p.dim },
  Folded = { fg = p.dim, bg = a[1] },
  StatusLine = { fg = p.sub },
  StatusLineNC = { fg = p.dim },
  StatusLineMode = { fg = p.solid, bg = p.hi, bold = true },
  StatusLineFile = { fg = p.sub },
  StatusLineInfo = { fg = p.dim },
  WinSeparator = { fg = p.line },
  TabLine = { fg = p.dim },
  TabLineSel = { fg = p.hi, bold = true },
  TabLineFill = {},
  WinBar = { fg = p.sub },
  WinBarNC = { fg = p.dim },
  Pmenu = { fg = p.fg, bg = p.solid },
  PmenuSel = { fg = p.hi, bg = p.sel, bold = true },
  PmenuKind = { fg = p.dim, bg = p.solid },
  PmenuExtra = { fg = p.dim, bg = p.solid },
  PmenuSbar = { bg = p.solid },
  PmenuThumb = { bg = p.line },
  WildMenu = { link = 'PmenuSel' },
  Search = { fg = p.solid, bg = p.sub },
  IncSearch = { fg = p.solid, bg = p.hi },
  CurSearch = { link = 'IncSearch' },
  Substitute = { link = 'IncSearch' },
  MatchParen = { fg = p.hi, bold = true, underline = true },
  NonText = { fg = p.line },
  Whitespace = { fg = p.line },
  SpecialKey = { fg = p.dim },
  EndOfBuffer = { fg = p.line },
  Conceal = { fg = p.dim },
  -- Colour of typeset math; autocmds.lua passes it into the LaTeX that snacks.image renders.
  SnacksImageMath = { fg = p.hi },
  Directory = { fg = p.hi },
  Title = { fg = p.hi, bold = true },
  ModeMsg = { fg = p.sub },
  MoreMsg = { fg = p.sub },
  Question = { fg = p.hi },
  ErrorMsg = { fg = red },
  WarningMsg = { fg = yellow },
  QuickFixLine = { bg = p.sel },
  SpellBad = { undercurl = true, sp = red },
  SpellCap = { undercurl = true, sp = yellow },
  SpellRare = { undercurl = true, sp = a[6] },
  SpellLocal = { undercurl = true, sp = cyan },

  -- Syntax
  Comment = { fg = p.dim, italic = true },
  Constant = { fg = yellow },
  String = { fg = p.sub },
  Character = { fg = p.sub },
  Number = { fg = yellow },
  Boolean = { fg = yellow },
  Float = { fg = yellow },
  Identifier = { fg = p.fg },
  Function = { fg = p.fg, bold = true },
  Statement = { fg = p.hi },
  Keyword = { fg = p.hi },
  Operator = { fg = p.sub },
  PreProc = { fg = p.sub },
  Type = { fg = p.sub },
  Special = { fg = p.hi },
  Delimiter = { fg = p.dim },
  Underlined = { underline = true },
  Error = { fg = red },
  Todo = { fg = p.solid, bg = p.hi, bold = true },
  Added = { fg = green },
  Changed = { fg = yellow },
  Removed = { fg = red },
  DiffAdd = { fg = green },
  DiffChange = { fg = yellow },
  DiffDelete = { fg = red },
  DiffText = { bg = p.sel },

  -- Diagnostics
  DiagnosticError = { fg = red },
  DiagnosticWarn = { fg = yellow },
  DiagnosticInfo = { fg = blue },
  DiagnosticHint = { fg = cyan },
  DiagnosticOk = { fg = green },
  DiagnosticUnderlineError = { undercurl = true, sp = red },
  DiagnosticUnderlineWarn = { undercurl = true, sp = yellow },
  DiagnosticUnderlineInfo = { undercurl = true, sp = blue },
  DiagnosticUnderlineHint = { undercurl = true, sp = cyan },

  -- Treesitter
  ['@variable'] = { fg = p.fg },
  ['@variable.builtin'] = { fg = p.hi },
  ['@module'] = { fg = p.sub },
  ['@property'] = { fg = p.fg },
  ['@punctuation'] = { fg = p.dim },
  ['@punctuation.special'] = { fg = p.dim },
  ['@tag'] = { fg = p.hi },
  ['@tag.attribute'] = { fg = p.sub },
  ['@tag.delimiter'] = { fg = p.dim },
  ['@markup.heading'] = { fg = p.hi, bold = true },
  ['@markup.strong'] = { fg = p.hi, bold = true },
  ['@markup.italic'] = { italic = true },
  ['@markup.strikethrough'] = { strikethrough = true },
  ['@markup.quote'] = { fg = p.sub, italic = true },
  ['@markup.list'] = { fg = p.sub },
  ['@markup.raw'] = { fg = p.sub },
  ['@markup.link'] = { fg = p.sub },
  ['@markup.link.label'] = { fg = p.sub },
  ['@markup.link.url'] = { fg = p.dim, underline = true },
  -- Raw math on the cursor line: plain symbols in fg, commands in hi, braces recede
  -- (after/queries/latex/highlights.scm dims the $ delimiters).
  ['@markup.math'] = { fg = p.fg },
  ['@markup.math.latex'] = { fg = p.fg },
  ['@function.latex'] = { fg = p.hi },
  ['@punctuation.bracket.latex'] = { fg = p.sub },

  -- render-markdown: monochrome headings, no backgrounds
  RenderMarkdownH1 = { fg = p.hi, bold = true },
  RenderMarkdownH2 = { fg = p.hi, bold = true },
  RenderMarkdownH3 = { fg = p.fg, bold = true },
  RenderMarkdownH4 = { fg = p.fg, bold = true },
  RenderMarkdownH5 = { fg = p.sub, bold = true },
  RenderMarkdownH6 = { fg = p.sub, bold = true },
  RenderMarkdownBullet = { fg = p.sub },
  RenderMarkdownCode = { bg = p.solid },
  RenderMarkdownCodeBorder = { bg = p.solid },
  RenderMarkdownCodeInline = { fg = p.sub },
  RenderMarkdownDash = { fg = p.line },
  RenderMarkdownQuote = { fg = p.dim },
  RenderMarkdownLink = { fg = p.sub },
  RenderMarkdownTableHead = { fg = p.line },
  RenderMarkdownTableRow = { fg = p.line },
  RenderMarkdownMath = { fg = p.hi },
  RenderMarkdownUnchecked = { fg = p.dim },
  RenderMarkdownChecked = { fg = p.sub },
}

for name, spec in pairs(groups) do
  vim.api.nvim_set_hl(0, name, spec)
end

for i = 0, 15 do
  vim.g['terminal_color_' .. i] = a[i + 1]
end
