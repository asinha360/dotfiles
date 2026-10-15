#!/bin/bash
# Battery charge from IOKit (pmset can omit the battery line), shown in the
# right wing and the island as a battery glyph and percentage, with a bolt on
# power and in red at 20% or less while discharging.
b=$(ioreg -rn AppleSmartBattery)
pct=$(awk '/"CurrentCapacity" =/ { print $3; exit }' <<<"$b")
ext=$(awk '/"ExternalConnected" =/ { print $3; exit }' <<<"$b")
case "$pct" in ''|*[!0-9]*) sketchybar --set wing.r label="--%" --set island.batt label="--%"; exit 0 ;; esac
# Font Awesome batteries (U+F240 full .. U+F244 empty) and bolt (U+F0E7), as UTF-8 for bash 3.2
if [ "$pct" -ge 88 ]; then g=$'\xef\x89\x80'
elif [ "$pct" -ge 63 ]; then g=$'\xef\x89\x81'
elif [ "$pct" -ge 38 ]; then g=$'\xef\x89\x82'
elif [ "$pct" -ge 13 ]; then g=$'\xef\x89\x83'
else g=$'\xef\x89\x84'; fi
low=off
if [ "$ext" = Yes ]; then g=$'\xef\x83\xa7 '"$g"; elif [ "$pct" -le 20 ]; then low=on; fi
label="$g  $pct%"
sketchybar --set wing.r label="$label" label.highlight=$low \
           --set island.batt label="$label" label.highlight=$low
