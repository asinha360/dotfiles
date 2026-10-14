#!/bin/bash
# wallsync hook, run as `apply.sh start|mid` at t0 and t0 + duration/2 of each change.
# Every action is fire-and-forget and tolerates its app not running.
phase="${1:-$WALLSYNC_PHASE}"
out="${WALLSYNC_OUT:-$HOME/.cache/wallsync/out}"
# Appended, not prepended, so callers can shadow tools.
PATH="$PATH:/opt/homebrew/bin"

case "$phase" in
start)
  [ -x "$out/sketchybar.sh" ] && "$out/sketchybar.sh" &
  [ -x "$out/borders.sh" ] && "$out/borders.sh" &
  pkill -USR2 -x cava
  ;;
mid)
  pkill -USR1 -x nvim
  if [ -f "$out/tmux.conf" ] && tmux list-sessions >/dev/null 2>&1; then
    tmux source-file "$out/tmux.conf" &
  fi
  ;;
*)
  echo "usage: apply.sh start|mid" >&2
  exit 1
  ;;
esac
exit 0
