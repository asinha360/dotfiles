#!/bin/bash
# Rendered by wallsync. Sourced by bordersrc for the colour variables only;
# executed by the start hook to recolour the running borders instance.
ACTIVE={{lineHi_argb}}
INACTIVE={{line_argb}}

[ "${BASH_SOURCE[0]}" != "$0" ] && return 0

# With arguments and no running instance, borders would start a new one.
pgrep -qx borders || exit 0
borders active_color=$ACTIVE inactive_color=$INACTIVE
