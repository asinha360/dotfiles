#!/bin/bash
# Workspace numbers 1-5 in the left pill. Each display has its own ws.<display>.<n>
# items and shows only the workspaces assigned to it (AeroSpace's NSScreen ids
# number displays the same way SketchyBar does). The workspace a display is
# showing is boxed: in LINE_HI and drawn in HI while focused, in LINE while focus
# is on another display. Ones holding windows are drawn in FG, empty ones in DIM.
# Runs on aerospace_workspace_change (FOCUSED comes from AeroSpace's
# exec-on-workspace-change; its focus callbacks send none), app switches and
# display changes.
AEROSPACE=/opt/homebrew/bin/aerospace
LINE=0x47AFB9C0 LINE_HI=0xB3E2E6E9 FG=0xFFD7DCE0 DIM=0xFF808C93 HI=0xFFEDF0F2
source "$HOME/.cache/wallsync/out/sketchybar.sh" 2>/dev/null

focused=${FOCUSED:-$("$AEROSPACE" list-workspaces --focused)}
busy=" $("$AEROSPACE" list-workspaces --monitor all --empty no | tr '\n' ' ')"
mon=() vis=()
while read -r w d v; do
  case "$w" in [1-5]) mon[$w]=$d vis[$w]=$v ;; esac
done < <("$AEROSPACE" list-workspaces --all \
           --format '%{workspace} %{monitor-appkit-nsscreen-screens-id} %{workspace-is-visible}')
args=()
for d in 1 2; do
  for i in 1 2 3 4 5; do
    if [ "${mon[$i]}" != "$d" ]; then
      args+=(--set ws.$d.$i label="" label.width=0 padding_left=0)
      continue
    fi
    b=0x00000000
    if [ "${vis[$i]}" = true ]; then
      if [ "$i" = "$focused" ]; then c=$HI b=$LINE_HI; else c=$FG b=$LINE; fi
    elif [[ "$busy" == *" $i "* ]]; then c=$FG
    else c=$DIM; fi
    args+=(--set ws.$d.$i label=$i label.width=22 padding_left=2 label.color=$c label.background.border_color=$b)
  done
done
sketchybar "${args[@]}"
