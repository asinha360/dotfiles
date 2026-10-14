# wallsync

A wallpaper engine for macOS 26. It changes the wallpaper on every display with a slanted wipe or a circle grow, and re-themes the terminal, tmux, nvim, SketchyBar, borders and cava from the wallpaper's dominant hue in the same transition.

## Usage
```
wallsync daemon                                            # run by the LaunchAgent
wallsync set <path> [--transition wipe|grow] [--origin x,y]
wallsync next|prev|random [--transition wipe|grow]
wallsync pick                                              # toggle the carousel (also ⌥W)
wallsync palette <path>                                    # JSON of every template variable
wallsync render <palette.json> <templates_dir> <out_dir>   # pure render, no daemon
wallsync status
```
Exit codes: 0 ok, 1 error, 3 daemon not running. Wallpapers come from `~/Pictures/walls`, or from `$WALLSYNC_DIR` when it is set.

Picker keys: `h`/`l` or the arrow keys move, `↵` applies, `esc` or a click on the backdrop closes it. Clicking a card applies that card, and the picker stays open after it applies a wallpaper. Every change picks wipe or grow at random unless `--transition` is given. A grow starts from the card when the wallpaper was applied from the picker, otherwise from `--origin` or the mouse.

```
make build      # swift build -c release
make test       # swift test
make install    # release build, then install and ad-hoc sign ~/.local/bin/wallsync
```
`launchd/com.user.wallsync.plist` uses `__HOME__` as a placeholder for the home directory. Replace it when installing, for example with `sed "s|__HOME__|$HOME|g"` into `~/Library/LaunchAgents/`.

## Architecture
- `WallsyncCore` is headless and unit-tested:
  - colour math (HSL, OKLab, WCAG)
  - hue extraction (64×40, a weighted 36-bin circular histogram)
  - the palette and its template variables
  - cubic-bezier easing
  - wipe and grow geometry
  - ImageIO decoding and thumbnails
  - `{{key}}` templates
  - OSC 4/10/11/12 frames (104/110/111/112 are never sent)
  - the Unix-socket IPC (newline-delimited JSON at `~/.cache/wallsync/wallsync.sock`)
  - the wallpaper list, state, and the sysctl tty scan
- The `wallsync` executable is an `.accessory` app:
  - desktop-level windows per screen, revealing the next image through an animated `CAShapeLayer` mask
  - the Ghostty tty morph (30fps OSC frames on the CA clock, then SIGUSR2)
  - the hooks
  - the Carbon ⌥W hotkey
  - the SwiftUI carousel in a nonactivating panel

What happens on each change:
1. Decode the image and extract the palette off the main thread.
2. Set t0 = now + 50ms.
3. Render `~/.config/wallsync/templates/*.tpl` into `~/.cache/wallsync/out/`.
4. Run `hooks/apply.sh start`.
5. Start the tty morph and the mask animation, both at t0.
6. Run `hooks/apply.sh mid` at t0 + duration/2.
7. At the end, set the system wallpaper and save `state.json`.

Requests that arrive during a transition are queued, and only the latest one is kept.

The palette formulas, template variables, hook phases and paths are specified in `../CONTRACT.md`. The golden values for H=205, C=0.2 are in `sample-palette.json`, which `PaletteTests` checks for exact equality.

Hue and chroma for each seed wallpaper (`wallsync palette walls/seed/*.png`):

| seed | H | C |
|---|---|---|
| aurora | 163 | 0.21 |
| ember | 7 | 0.69 |
| fog | 204 | 0.31 |
| neon | 255 | 0.12 |
| pine | 161 | 0.20 |
| snow | 205 | 0.00 |
