#!/bin/bash
# The left wing and the island show the same time; displays.sh decides where each draws.
label=$(date '+%a %-d  %H:%M')
sketchybar --set wing.l label="$label" --set island.time label="$label"
