#!/bin/bash
# Focus timer item, polled every second. A click starts a 50-minute block, or
# stops the running one. `focus status` also closes a block that has ended.
FOCUS="$HOME/.local/bin/focus"
if [ "$SENDER" = mouse.clicked ]; then
  if [ -n "$("$FOCUS" status)" ]; then "$FOCUS" stop; else "$FOCUS" 50; fi
fi
label=$("$FOCUS" status)
sketchybar --set "$NAME" label="${label:-◷ --:--}"
