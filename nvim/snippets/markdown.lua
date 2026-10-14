-- Markdown autosnippets on top of luasnip-latex-snippets (which supplies the
-- math-mode set; cheat sheet in the vault at math/00-latex-snippets.md).
local ls = require('luasnip')
local s, t, i = ls.snippet, ls.text_node, ls.insert_node
local ts = require('luasnip-latex-snippets.util.ts_utils')

local function in_code()
  local node = vim.treesitter.get_node({ ignore_injections = true })
  while node do
    local kind = node:type()
    if kind == 'fenced_code_block' or kind == 'indented_code_block' then
      return true
    end
    node = node:parent()
  end
  return false
end

-- An odd number of backticks before the cursor means an unclosed code span, which
-- treesitter cannot see while it is being typed.
local function prose(line_to_cursor)
  return select(2, line_to_cursor:gsub('`', '')) % 2 == 0 and ts.in_text(true) and not in_code()
end

local function in_math()
  return ts.in_mathzone()
end

local auto = {
  s({ trig = 'mk', name = 'inline math', priority = 1000, condition = prose }, { t('$'), i(1), t('$'), i(0) }),
  s(
    { trig = 'dm', name = 'display math', priority = 1000, condition = prose },
    { t({ '$$', '' }), i(1), t({ '', '$$' }), i(0) }
  ),
  s({ trig = 'ff', name = 'fraction', condition = in_math }, { t('\\frac{'), i(1), t('}{'), i(2), t('}'), i(0) }),
}

local greek = {
  a = 'alpha', b = 'beta', g = 'gamma', d = 'delta', e = 'epsilon', z = 'zeta', h = 'eta',
  q = 'theta', i = 'iota', k = 'kappa', l = 'lambda', m = 'mu', n = 'nu', x = 'xi', p = 'pi',
  r = 'rho', s = 'sigma', t = 'tau', u = 'upsilon', f = 'phi', c = 'chi', y = 'psi', w = 'omega',
  G = 'Gamma', D = 'Delta', Q = 'Theta', L = 'Lambda', X = 'Xi', P = 'Pi', S = 'Sigma',
  U = 'Upsilon', F = 'Phi', Y = 'Psi', W = 'Omega',
}
for key, name in pairs(greek) do
  auto[#auto + 1] = s({ trig = ';' .. key, name = name, wordTrig = false, condition = in_math }, t('\\' .. name))
end

return {}, auto
