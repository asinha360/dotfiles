# CONTRACT — Monolith rice

The shared interface between components. Every builder codes against this file. The spec and rationale live in `~/.claude/plans/peppy-kindling-journal.md`. The visual reference is canvas board **A · Monolith** (https://claude.ai/artifact/MXoiCQe4cmGm7xVWfNE9o3), with two changes: **FiraCode Nerd Font** everywhere and random wipe/grow transitions.

## Hard rules for builders
- Work only inside your owned paths (see the Ownership table). Templates go in `wallsync/templates/`, one file per consumer, named after the owner's output.
- **Do not change live system state.** No symlinks into `~/.config` or `~`, no `brew services`, no `launchctl`, no `defaults write`, no `tmux kill-server`, no sending signals to running apps, and no editing `~/.claude/settings.json`. Test in isolation (scratch dirs, `XDG_CONFIG_HOME`/`XDG_DATA_HOME`/`NVIM_APPNAME`, `tmux -L <test-socket>`). Integration happens later, done by the orchestrator.
- The tmux session `Assistant` is live and must never be touched.
- Keep code minimal and match the surrounding idiom. No emojis in code or comments.

## Paths (installed locations)
| What | Path |
|---|---|
| Repo | `~/projects/dotfiles` |
| wallsync binary | `~/.local/bin/wallsync` (`~/.local/bin` is already on PATH) |
| Other scripts (`bin/*`) | symlinked to `~/.local/bin/<name>` |
| Templates (source) | `~/.config/wallsync/templates/*.tpl` (symlink → `repo/wallsync/templates`) |
| Hook | `~/.config/wallsync/hooks/apply.sh` (symlink → `repo/wallsync/hooks/apply.sh`) |
| Rendered output | `~/.cache/wallsync/out/<template name without .tpl>`. Files ending in `.sh` are made executable |
| State / socket / thumbs | `~/.cache/wallsync/state.json`, `~/.cache/wallsync/wallsync.sock`, `~/.cache/wallsync/thumbs/` |
| Wallpapers | `~/Pictures/walls` (override: env `WALLSYNC_DIR`). Seeds: `repo/walls/seed/*.png` |
| Log | `~/Library/Logs/wallsync.log` |
| Study vault | `~/projects/study-vault` |
| Ghostty config | `~/.config/ghostty/config.ghostty` |
| AeroSpace | `~/.config/aerospace/aerospace.toml` |
| SketchyBar | `~/.config/sketchybar/` |
| borders | `~/.config/borders/bordersrc` |
| cava | `~/.config/cava/config` |
| nvim | `~/.config/nvim` |
| tmux | `~/.tmux.conf` + `~/.config/tmux/` |

## Palette
H is the dominant hue as an integer degree (rounded, mod 360). C is the chroma factor in 0..1 (2 decimals). HSL→RGB uses the CSS algorithm, with each channel computed as `Int(x*255 + 0.5)`.

| key | HSL | alpha |
|---|---|---|
| panel | H,14,8 | 0.70 |
| solid | H,14,9 | 1 |
| pill | H,14,8 | 0.62 |
| line | H,12,72 | 0.28 |
| lineHi | H,14,90 | 0.70 |
| fg | H,12,86 | 1 |
| sub | H,9,70 | 1 |
| dim | H,8,54 | 1 |
| hi | H,16,94 | 1 |
| sel | H,12,32 | 0.55 |
| ansi0 | H,14,12 | 1 |
| ansi7 / ansi8 / ansi15 | = fg / dim / hi | 1 |
| ansi1..6 | slot (hue,L): red(355,69) green(140,66) yellow(42,67) blue(212,72) magenta(300,70) cyan(185,66); S = 22+12·C | 1 |
| ansi9..14 | same as 1..6 with L+8 | 1 |

ANSI hue pull: Δ = the shortest signed angle from the slot hue to H, in (−180,180]. Then h = (slot + clamp(0.15·Δ, −12, 12)) mod 360.

**Template variables** (for every key above):
- `{{k}}` = `RRGGBB`
- `{{k_hex}}` = `#RRGGBB`
- `{{k_argb}}` = `0xAARRGGBB`, where AA = `Int(alpha*255+0.5)`
- `{{k_flat}}` = `#RRGGBB`, composited over the opaque panel colour: per channel `Int(a*c + (1-a)*p + 0.5)`
- `{{k_flat_argb}}` = `0xFF` + the flat colour

Scalars: `{{H}}`, `{{C}}`, `{{wallpaper}}` (absolute path).

Unknown `{{x}}` placeholders are left as they are. Golden values for H=205, C=0.2 are in `wallsync/sample-palette.json`. wallsync must reproduce them exactly, and consumers use that file to test their templates (render with any `{{key}}` substitution loop).

Constraints: fg contrast ≥ 7:1 and ansi1–15 ≥ 3:1 against the opaque panel colour.

## Templates (owner → file → purpose)
| Owner | Template | Output and how it is applied |
|---|---|---|
| B2 | `ghostty.conf.tpl` | `background={{panel_hex}}`, `foreground={{fg_hex}}`, `cursor-color={{hi_hex}}`, `cursor-text={{solid_hex}}`, `selection-background={{sel_flat}}`, `selection-foreground={{hi_hex}}`, `palette = N={{ansiN_hex}}` for 0..15. Included by Ghostty's config. Must match the OSC frame mapping: 10=fg, 11=panel, 12=hi |
| B2 | `tmux.conf.tpl` | Every colour-bearing tmux option (hex). Run with `tmux source-file` in the `mid` phase. **Never set `cursor-colour`** |
| B3 | `nvim.lua.tpl` | `return { H=..., panel=, solid=, line=(flat), lineHi=(flat), fg=, sub=, dim=, hi=, sel=(flat), ansi={16 hex} }`. Read by `colors/monolith.lua` |
| B4 | `sketchybar.sh.tpl` | Executable. Recolours the bar and pills, animated over `$WALLSYNC_DURATION_MS` (`sketchybar --animate`). Also sourced by `sketchybarrc` at startup with no animation (when `WALLSYNC_DURATION_MS` is empty) |
| B4 | `borders.sh.tpl` | Executable. `borders active_color={{lineHi_argb}} inactive_color={{line_argb}} ...` (updates the running instance live) |
| B4 | `cava.theme.tpl` | A cava colour theme file (gradient dim→hi). cava's config points `theme` at it |

## Hook: `wallsync/hooks/apply.sh <phase>` (owner B1)
Environment: `WALLSYNC_OUT`, `WALLSYNC_PHASE`, `WALLSYNC_DURATION_MS`, `WALLSYNC_WALLPAPER`. PATH includes `/opt/homebrew/bin`. Each action is fire-and-forget and must tolerate the app not running.
- `start` (at t0): `"$WALLSYNC_OUT/sketchybar.sh" &`, `"$WALLSYNC_OUT/borders.sh" &`, `pkill -USR2 -x cava`.
- `mid` (at t0 + dur/2): `pkill -USR1 -x nvim`; if a tmux server is running, `tmux source-file "$WALLSYNC_OUT/tmux.conf"`.

## wallsync CLI (owner B1)
```
wallsync daemon
wallsync set <path> [--transition wipe|grow] [--origin x,y]
wallsync next|prev|random [--transition wipe|grow]
wallsync pick
wallsync palette <path>             # JSON with every template variable (no daemon needed)
wallsync render <palette.json> <templates_dir> <out_dir>   # pure render, for tests and integration
wallsync status
```
Exit codes: 0 ok, 1 error, 3 daemon not running. IPC: Unix socket, newline-delimited JSON. The global hotkey is **⌥W** (Carbon). Nothing else may bind `alt-w`.

## Cross-component names
- **Claude state** → SketchyBar: `sketchybar --trigger claude_state STATE=running|waiting|idle SESSION=<tmux session name or cwd basename>` (B4 owns both the item and the hooks fragment).
- **Study sessions** (B2 `bin/study`): `vault`, `notes`, `cava`, `ask`. Window title = tmux session name (`set-titles-string '#S'`), so AeroSpace can identify the windows.
  - `vault`: `yazi ~/projects/study-vault` on top 70%, `vault-due --watch` below.
  - `notes`: `nvim` in the vault.
  - `cava`: `cava`.
  - `ask`: `claude` in the vault.
- **Build sessions** (B2 `bin/build`): `code`, `agent`, `bench` (cwd given as an argument, default `$PWD`).
- **Scripts:**
  - `vault-due [--watch]` (B3) prints due notes: `name<TAB>due-label`.
  - `focus [50|25|stop|status]` (B4).
  - `bar-stats` (B4).
- **Fonts:** Ghostty `FiraCode Nerd Font`; SketchyBar `FiraCode Nerd Font:Regular:11.0`; LaTeX `stix2`.

## Ownership
| Builder | Owns |
|---|---|
| B1 | `wallsync/**` except other builders' `templates/*.tpl`; `walls/` |
| B2 | `ghostty/`, `tmux/`, `aerospace/`, `zsh/`, `starship/`, `yazi/`, `lazygit/`, `btop/`, `bin/study`, `bin/build`, `wallsync/templates/{ghostty.conf,tmux.conf}.tpl` |
| B3 | `nvim/`, `vault-scaffold/` (copied to `~/projects/study-vault` at integration), `bin/vault-due`, `wallsync/templates/nvim.lua.tpl` |
| B4 | `sketchybar/`, `borders/`, `cava/`, `bin/focus`, `bin/bar-stats`, `claude/settings.fragment.json`, `wallsync/templates/{sketchybar.sh,borders.sh,cava.theme}.tpl` |
| Orchestrator | `install.sh`, `Brewfile`, `CONTRACT.md`, `README.md`, integration |
