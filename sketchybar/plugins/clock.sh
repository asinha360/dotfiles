#!/bin/bash
# Both clock items show the same time; displays.sh decides where each draws.
label=$(date '+%a %-d %b  %H:%M')
sketchybar --set clock label="$label" --set clock.notch label="$label"
