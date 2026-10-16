#!/bin/bash
# Link the Monolith rice into place, build wallsync, scaffold the vault.
#   ./install.sh             link + build (no services started)
#   ./install.sh --dry-run   print what would happen
#   ./install.sh --services  also start wallsync, sketchybar, borders, AeroSpace
#   ./install.sh --uninstall remove links, stop services, restore backups
set -e

REPO="$(cd "$(dirname "$0")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/2026-10-14"
DRY=0; SERVICES=0; UNINSTALL=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --services) SERVICES=1 ;;
    --uninstall) UNINSTALL=1 ;;
    *) echo "unknown option: $a" >&2; exit 1 ;;
  esac
done

run() { if [ $DRY = 1 ]; then echo "+ $*"; else "$@"; fi; }

# source (repo-relative) -> target
LINKS="
ghostty/config.ghostty|$HOME/.config/ghostty/config.ghostty
tmux/tmux.conf|$HOME/.tmux.conf
tmux/monolith.conf|$HOME/.config/tmux/monolith.conf
tmux/minimal.conf|$HOME/.config/tmux/minimal.conf
tmux/pills.conf|$HOME/.config/tmux/pills.conf
tmux/panes.conf|$HOME/.config/tmux/panes.conf
tmux/cheatsheet.txt|$HOME/.config/tmux/cheatsheet.txt
tmux/cheatsheet.awk|$HOME/.config/tmux/cheatsheet.awk
aerospace/aerospace.toml|$HOME/.config/aerospace/aerospace.toml
sketchybar|$HOME/.config/sketchybar
borders/bordersrc|$HOME/.config/borders/bordersrc
cava/config|$HOME/.config/cava/config
nvim|$HOME/.config/nvim
zsh/.zshrc|$HOME/.zshrc
starship/starship.toml|$HOME/.config/starship.toml
yazi|$HOME/.config/yazi
lazygit/config.yml|$HOME/Library/Application Support/lazygit/config.yml
btop/btop.conf|$HOME/.config/btop/btop.conf
wallsync/templates|$HOME/.config/wallsync/templates
wallsync/hooks|$HOME/.config/wallsync/hooks
bin/study|$HOME/.local/bin/study
bin/build|$HOME/.local/bin/build
bin/focus|$HOME/.local/bin/focus
bin/vault-due|$HOME/.local/bin/vault-due
bin/bar-stats|$HOME/.local/bin/bar-stats
"

PLIST="$HOME/Library/LaunchAgents/com.user.wallsync.plist"
UID_GUI="gui/$(id -u)"

link_one() {
  src="$REPO/$1"; dst="$2"
  [ -e "$src" ] || { echo "skip (missing in repo): $1"; return; }
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then return; fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    run mkdir -p "$BACKUP/replaced"
    # Never overwrite an earlier backup: the unsuffixed one is the original that --uninstall restores
    saved="$BACKUP/replaced/$(echo "$dst" | sed "s|$HOME/||; s|/|__|g")"; n=$saved; i=0
    while [ -e "$n" ] || [ -L "$n" ]; do i=$((i + 1)); n="$saved.$i"; done
    run mv "$dst" "$n"
  fi
  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
  echo "linked $dst"
}

unlink_one() {
  src="$REPO/$1"; dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then run rm "$dst"; echo "removed $dst"; fi
  saved="$BACKUP/replaced/$(echo "$dst" | sed "s|$HOME/||; s|/|__|g")"
  if [ -e "$saved" ] && [ ! -e "$dst" ]; then run mv "$saved" "$dst"; echo "restored $dst"; fi
}

if [ $UNINSTALL = 1 ]; then
  run launchctl bootout "$UID_GUI/com.user.wallsync" 2>/dev/null || true
  run rm -f "$PLIST"
  run brew services stop sketchybar 2>/dev/null || true
  run brew services stop borders 2>/dev/null || true
  run osascript -e 'quit app "AeroSpace"' 2>/dev/null || true
  echo "$LINKS" | while IFS='|' read -r s d; do [ -z "$s" ] || unlink_one "$s" "$d"; done
  run open -a Rectangle 2>/dev/null || true
  echo "uninstalled (wallsync binary left at ~/.local/bin/wallsync, vault left at ~/projects/study-vault)"
  exit 0
fi

echo "$LINKS" | while IFS='|' read -r s d; do [ -z "$s" ] || link_one "$s" "$d"; done

# cava reads its theme by name from ~/.config/cava/themes
run mkdir -p "$HOME/.config/cava/themes" "$HOME/.cache/wallsync/out"
[ -L "$HOME/.config/cava/themes/wallsync" ] || run ln -s "$HOME/.cache/wallsync/out/cava.theme" "$HOME/.config/cava/themes/wallsync"

# Wallpapers: seed only an empty folder
run mkdir -p "$HOME/Pictures/walls"
if [ -z "$(ls -A "$HOME/Pictures/walls" 2>/dev/null)" ]; then run cp "$REPO"/walls/seed/*.png "$HOME/Pictures/walls/"; fi

# Study vault: scaffold once, never overwrite
if [ ! -d "$HOME/projects/study-vault" ] && [ -d "$REPO/vault-scaffold" ]; then
  run cp -R "$REPO/vault-scaffold" "$HOME/projects/study-vault"
  run git -C "$HOME/projects/study-vault" init -q -b main
fi

# tmux plugin manager
for p in tpm tmux-resurrect tmux-continuum; do
  [ -d "$HOME/.tmux/plugins/$p" ] || run git clone -q "https://github.com/tmux-plugins/$p" "$HOME/.tmux/plugins/$p"
done

# wallsync binary + LaunchAgent
run make -C "$REPO/wallsync" install
if [ $DRY = 1 ]; then echo "+ render $PLIST"; else
  mkdir -p "$(dirname "$PLIST")"
  sed "s|__HOME__|$HOME|g" "$REPO/wallsync/launchd/com.user.wallsync.plist" > "$PLIST"
fi

# First render, so cava's theme, Ghostty's include and the rest exist before any wallpaper change
OUT="$HOME/.cache/wallsync/out"
first=$(ls "$HOME"/Pictures/walls/*.png "$HOME"/Pictures/walls/*.jpg 2>/dev/null | head -1)
if [ ! -e "$OUT/palette.json" ] && [ -n "$first" ]; then
  if [ $DRY = 1 ]; then echo "+ render palette of $first into $OUT"; else
    "$HOME/.local/bin/wallsync" palette "$first" > "$OUT/palette.json"
    "$HOME/.local/bin/wallsync" render "$OUT/palette.json" "$REPO/wallsync/templates" "$OUT"
  fi
fi

if [ $SERVICES = 1 ]; then
  run launchctl bootout "$UID_GUI/com.user.wallsync" 2>/dev/null || true
  run launchctl bootstrap "$UID_GUI" "$PLIST"
  run brew services start sketchybar
  run brew services start borders
  # Rectangle would fight AeroSpace over window frames; --uninstall reopens it
  run osascript -e 'quit app "Rectangle"' 2>/dev/null || true
  run osascript -e 'tell application "System Events" to delete login item "Rectangle"' 2>/dev/null || true
  run open -a AeroSpace
fi
echo "done"
