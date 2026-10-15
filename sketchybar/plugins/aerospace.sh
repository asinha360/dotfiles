#!/bin/bash
# Workspace numbers 1-5 in the left pill: the focused one boxed in LINE_HI and
# drawn in HI, ones holding windows in FG, empty ones in DIM. Runs on
# aerospace_workspace_change (FOCUSED comes from AeroSpace's
# exec-on-workspace-change; its on-focus-changed sends none) and on app switches.
AEROSPACE=/opt/homebrew/bin/aerospace
LINE_HI=0xB3E2E6E9 FG=0xFFD7DCE0 DIM=0xFF808C93 HI=0xFFEDF0F2
source "$HOME/.cache/wallsync/out/sketchybar.sh" 2>/dev/null

focused=${FOCUSED:-$("$AEROSPACE" list-workspaces --focused)}
busy=" $("$AEROSPACE" list-workspaces --monitor all --empty no | tr '\n' ' ')"
args=()
for i in 1 2 3 4 5; do
  if [ "$i" = "$focused" ]; then c=$HI b=$LINE_HI
  elif [[ "$busy" == *" $i "* ]]; then c=$FG b=0x00000000
  else c=$DIM b=0x00000000; fi
  args+=(--set ws.$i label.color=$c label.background.border_color=$b)
done
sketchybar "${args[@]}"
