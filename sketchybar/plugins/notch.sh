#!/bin/zsh
# Keeps the notch current without polling lag: the clock redraws in the first
# ~20ms of each minute (the loop wakes on every whole second without forking),
# the battery as soon as macOS posts a percentage or power-source change (the
# notify(3) keys behind the system battery indicator). Started by sketchybarrc;
# a new start replaces the running instance, and it exits with SketchyBar.
zmodload zsh/datetime zsh/zselect
dir=${0:A:h}
pidfile=${TMPDIR:-/tmp}/sketchybar-notch.pid
[[ -r $pidfile ]] && old=$(<$pidfile)
print $$ > $pidfile
if [[ -n $old && $old != $$ && $(ps -p $old -o command= 2>/dev/null) == *notch.sh* ]]; then
  pkill -P $old
  kill $old
fi

while :; do
  if (( EPOCHSECONDS / 60 != minute )); then
    pgrep -qx sketchybar || break
    $dir/clock.sh
    (( minute = EPOCHSECONDS / 60 ))
    # notifyutil prints a line per notification; reopened here if it ever exits.
    [[ -z $fd ]] && exec {fd}< <(exec notifyutil -w com.apple.system.powersources.percent \
                                                 -w com.apple.system.powersources.source)
  fi
  t=$EPOCHREALTIME
  zselect -t $(( 101 - ${${t#*.}[1,2]} )) $fd || continue
  if read -r -u $fd _; then $dir/battery.sh; else exec {fd}<&-; unset fd; fi
done
pkill -P $$
