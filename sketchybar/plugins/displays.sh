#!/bin/bash
# Puts `clock.notch` on notched displays and `clock` on the others.
# SketchyBar addresses displays by arrangement id; notched screens (NSScreen
# safe-area top inset > 0) are matched to it through CGDirectDisplayID.
# display_change also fires when the pointer moves between displays, so event
# runs re-probe only when the display layout changed; a direct call (no
# SENDER, as in sketchybarrc) always does. A failed probe leaves the placement
# alone and is not cached, so the next event (or wake) probes again.
NOWHERE=30   # no display has this arrangement id: hides an item without drawing=off

displays=$(sketchybar --query displays)
[ -n "$displays" ] || exit 0
cache="${TMPDIR:-/tmp}/sketchybar-displays"
[ -n "$SENDER" ] && [ "$displays" = "$(cat "$cache" 2>/dev/null)" ] && exit 0

notched=$(osascript -l JavaScript -e '
  ObjC.import("AppKit");
  var s = $.NSScreen.screens, ids = [];
  for (var i = 0; i < s.count; i++)
    if (s.objectAtIndex(i).safeAreaInsets.top > 0)
      ids.push(ObjC.unwrap(s.objectAtIndex(i).deviceDescription.objectForKey("NSScreenNumber")));
  ids.join(",")' 2>/dev/null) &&
ids=$(printf '%s' "$displays" | jq -r --argjson n "[$notched]" '
  (map(select(.DirectDisplayID | IN($n[])) | ."arrangement-id")) as $in
  | [($in | join(",")), (map(."arrangement-id") - $in | join(","))] | @tsv') ||
  { rm -f "$cache"; exit 1; }
printf '%s' "$displays" > "$cache"
notch=${ids%%$'\t'*}
plain=${ids#*$'\t'}
sketchybar --set clock display=${plain:-$NOWHERE} --set clock.notch display=${notch:-$NOWHERE}
