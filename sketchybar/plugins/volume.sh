#!/bin/bash
# volume_change passes the new volume in INFO; the forced startup run does not.
if [ "$SENDER" = volume_change ]; then
  vol=$INFO
else
  vol=$(osascript -e 'output volume of (get volume settings)')
fi
case "$vol" in ''|*[!0-9]*) vol=-- ;; esac
sketchybar --set "$NAME" label="vol $vol%"
