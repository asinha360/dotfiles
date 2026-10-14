# study-vault

Plain Markdown notes, edited in Neovim and readable by the Obsidian app.

## Layout

| folder | contents |
| --- | --- |
| `math/` `fpga/` `quant/` | notes, one idea per file, numbered within a topic (`05-spectral.md`) |
| `daily/` | daily notes, `YYYY-MM-DD.md` |
| `templates/` | `note.md` and `daily.md`, used by both obsidian.nvim and Obsidian |
| `_attachments/` | images and PDFs; links resolve here in nvim (snacks.image) and Obsidian |
| `.obsidian/` | minimal app config: core plugins, daily notes, templates, attachment folder |

## Frontmatter

```yaml
---
tags:
  - linear-algebra
created: 2026-10-07
sr-due: 2026-10-14
---
```

`sr-due` is the next review date. It is the field the obsidian-spaced-repetition
plugin writes, so reviews done in Obsidian move it too. `vault-due` lists every
note due within the next week (`today`, `overdue Nd`, or the weekday); it runs
below yazi in the `vault` panel and refreshes every 5 minutes. Notes without
`sr-due` (references, daily notes) never show up there.

## Neovim

Open any note in the vault with `nvim` (the `notes` panel does this).

| key | action |
| --- | --- |
| `<space>on` | new note from `templates/note.md` |
| `<space>od` | today's daily note |
| `<space>oo` / `<space>os` | switch note / search the vault |
| `<space>ob` | backlinks |
| `<space>ot` | insert a template |
| `<space>m` | show the math or image under the cursor in a float |
| `<space>ff` / `<space>fg` / `<space>e` | files / grep / explorer |

Math between `$ $` and `$$ $$` is typeset with tectonic in STIX Two and shown
inline; the line under the cursor shows the LaTeX source. Snippet triggers are
in `math/00-latex-snippets.md`. Changing the wallpaper re-colours the editor
and re-renders the math.

## Obsidian

Open this folder as a vault. Wiki links, tags, templates and attachments work
the same way in both editors. obsidian.nvim never rewrites frontmatter when it
saves a note; new notes get theirs from `templates/note.md`.
