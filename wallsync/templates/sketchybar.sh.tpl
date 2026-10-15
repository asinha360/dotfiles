#!/bin/bash
# Rendered by wallsync. Sourced by sketchybarrc for the colour variables only;
# executed by the start hook to recolour the bar, animated over
# $WALLSYNC_DURATION_MS when it is set.
PILL={{pill_argb}}
LINE={{line_argb}}
LINE_HI={{lineHi_argb}}
FG={{fg_argb}}
SUB={{sub_argb}}
DIM={{dim_argb}}
HI={{hi_argb}}
RED={{ansi1_argb}}

[ "${BASH_SOURCE[0]}" != "$0" ] && return 0

args=()
frames=$(( ${WALLSYNC_DURATION_MS:-0} * 60 / 1000 ))
[ "$frames" -gt 0 ] && args=(--animate tanh $frames)
args+=(--set '/^pill\./' background.color=$PILL background.border_color=$LINE)
for item in cpu gpu ram temp wing.l wing.r island.time island.batt focus vol; do
  args+=(--set $item label.color=$FG)
done
args+=(--set claude label.color=$SUB label.highlight_color=$HI
       --set wing.r label.highlight_color=$RED --set island.batt label.highlight_color=$RED
       --set ws.sep background.color=$LINE
       --set wall label.color=$HI label.background.border_color=$LINE_HI)
sketchybar "${args[@]}"
# Workspace numbers take their colours from this file when their script reruns
sketchybar --trigger aerospace_workspace_change
