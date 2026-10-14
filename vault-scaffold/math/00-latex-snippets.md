---
tags:
  - reference
  - latex
created: 2026-10-14
---

# LaTeX snippets

Snippets from luasnip-latex-snippets.nvim plus the custom ones in
`nvim/snippets/markdown.lua`. Math context is decided by treesitter, so math
snippets fire only between `$ $` or `$$ $$` and never inside code blocks.

## Prose (outside math)

| trigger | result |
| --- | --- |
| `mk` | `$ $`, cursor inside |
| `dm` | `$$` block, delimiters on their own lines |

## Custom (inside math)

| trigger | result |
| --- | --- |
| `ff` | `\frac{}{}` |
| `;a` `;b` `;g` `;d` `;e` `;z` `;h` `;q` | `\alpha \beta \gamma \delta \epsilon \zeta \eta \theta` |
| `;i` `;k` `;l` `;m` `;n` `;x` `;p` `;r` | `\iota \kappa \lambda \mu \nu \xi \pi \rho` |
| `;s` `;t` `;u` `;f` `;c` `;y` `;w` | `\sigma \tau \upsilon \phi \chi \psi \omega` |
| `;G` `;D` `;Q` `;L` `;X` `;P` `;S` `;U` `;F` `;Y` `;W` | capital Greek |

## Automatic (inside math)

| trigger | result |
| --- | --- |
| `//` | `\frac{}{}` |
| `a/` `x_1/` `(a+b)/` | `\frac{a}{}`, `\frac{x_1}{}`, `\frac{a+b}{}` |
| `x1` `x_12` | `x_{1}` `x_{12}` |
| `td` `rd` `sr` `cb` | `^{}` `^{()}` `^2` `^3` |
| `__` `invs` `compl` | `_{}` `^{-1}` `^{c}` |
| `sq` | `\sqrt{}` |
| `alpha` `lambda` `Sigma` ... | `\alpha` `\lambda` `\Sigma` (any Greek name; also `varepsilon varphi varrho vartheta`) |
| `sin cos tan csc sec cot ln log exp int star perp quad qquad` | the `\`-command |
| `arcsin arctan arcsec asin atan asec` | `\arcsin` ... |
| `xhat` `xbar` `xund` `xdot` `xora` `xola` | `\hat{x}` `\overline{x}` `\underline{x}` `\dot{x}` `\overrightarrow{x}` `\overleftarrow{x}` |
| `hat` `bar` `conj` | `\hat{}` `\overline{}` `\overline{}` |
| `x.,` `x,.` | `\vec{x}` |
| `norm` `abs` `floor` `ceil` | norm bars, `\abs{}`, `\lfloor \rfloor`, `\lceil \rceil` |
| `set` `case` `cvec` `bmat` | `\{\}`, `cases`, column vector, `bmatrix` |
| `tt` `stt` `mcal` `SI` | `\text{}` `_\text{}` `\mathcal{}` `\SI{}{}` |
| `RR` `QQ` `ZZ` `NN` `DD` `HH` `R0+` | `\mathbb{R}` ... `\mathbb{R}_0^+` |
| `<=` `>=` `!=` `~~` `>>` `<<` `**` `xx` | `\le \ge \neq \sim \gg \ll \cdot \times` |
| `->` `-->` `<->` `!>` `=>` `=<` `iff` `simp` `siff` | `\to \longrightarrow \leftrightarrow \mapsto \implies \impliedby \iff \Rightarrow \Leftrightarrow` |
| `inn` `notin` `cc` `UU` `Nn` `uuu` `nnn` `OO` | `\in \not\in \subset \cup \cap \bigcup \bigcap \O` |
| `EE` `AA` `ooo` `inf` `nabl` `lll` `...` `\\\` | `\exists \forall \infty \infty \nabla \ell \ldots \setminus` |
| `\|\|` `:=` `<>` `<!` `==` | `\mid \coloneqq \diamond \triangleleft &= \\` |
| `xnn` `ynn` `xii` `yii` `xjj` `yjj` `xp1` `xmm` | `x_{n}` ... `x_{n+1}` `x_{m}` |
| `dint` | `\int_{-\infty}^{\infty}` |
| `rij` `letw` `fun` | `(x_n)_{n\in\N}`, Let Ω ⊂ ℂ be open, `f \colon \R \to \R` |
| `ali` `beg` `bigfun` (line start) | `align*`, `\begin{}...\end{}`, big function |

## From the completion menu (inside math)

`sum` `taylor` `lim` `limsup` `prod` `part` `ddx` `pmat` `lr` `lr(` `lr|`
`lr{` `lr[` `lra` `lrb` `sequence`. Accept with `<C-y>`, jump between fields
with `<Tab>` / `<S-Tab>`.
