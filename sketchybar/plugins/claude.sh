#!/bin/bash
# Claude Code state per instance, from the claude_state event (STATE, SESSION,
# ID = the Claude process id). Each instance keeps "<state> <session>" in its
# own file; idle removes it. Stop does not fire on a user interrupt, so the
# 30s routine run also drops entries whose Claude process is gone and running
# entries untouched for 30 minutes. Shown: the newest waiting instance, else
# the newest running one, else nothing (empty label, no gap).
dir="$HOME/.cache/claude-bar"
mkdir -p "$dir"

if [ "$SENDER" = claude_state ]; then
  id=${ID:-$SESSION}
  id=${id//[!A-Za-z0-9_.%-]/_}
  case "$STATE" in
    running|waiting) printf '%s %s\n' "$STATE" "$SESSION" > "$dir/.$id" && mv "$dir/.$id" "$dir/$id" ;;
    *) rm -f "$dir/$id" ;;
  esac
fi

find "$dir" -type f -mmin +30 -exec grep -q '^running ' {} \; -delete
running="" waiting=""
for id in $(ls -t "$dir"); do
  case "$id" in *[!0-9]*) ;; *) kill -0 "$id" 2>/dev/null || { rm -f "$dir/$id"; continue; } ;; esac
  read -r state session 2>/dev/null < "$dir/$id" || continue
  case "$state" in
    waiting) [ -n "$waiting" ] || waiting=$session ;;
    running) [ -n "$running" ] || running=$session ;;
  esac
done

label="" highlight=off pad=0
if [ -n "$waiting" ]; then
  label="! $waiting" highlight=on pad=14
elif [ -n "$running" ]; then
  label="● $running" pad=14
fi
sketchybar --set "$NAME" label="$label" padding_right=$pad label.highlight=$highlight
