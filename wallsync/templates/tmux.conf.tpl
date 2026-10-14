# Rendered by wallsync and applied with `tmux source-file` (mid phase).
# Colours only: formats live in monolith.conf. Panes keep the default
# background so Ghostty's translucency shows. Never set cursor-colour.

# Label colours read by pane-border-format
set -g @mono_fg '{{fg_hex}}'
set -g @mono_dim '{{dim_hex}}'

set -g status-style 'bg=default,fg={{dim_hex}}'
set -g status-left-style 'fg={{hi_hex}},bold'
set -g status-right-style 'fg={{dim_hex}}'
setw -g window-status-style 'fg={{dim_hex}}'
setw -g window-status-current-style 'fg={{hi_hex}},bold'
setw -g window-status-last-style 'fg={{sub_hex}}'
setw -g window-status-activity-style 'fg={{fg_hex}},underscore'
setw -g window-status-bell-style 'fg={{ansi1_hex}},bold'

setw -g pane-border-style 'fg={{line_flat}}'
setw -g pane-active-border-style 'fg={{lineHi_flat}}'

set -g message-style 'bg={{solid_hex}},fg={{hi_hex}}'
set -g message-command-style 'bg={{solid_hex}},fg={{sub_hex}}'
setw -g mode-style 'bg={{sel_flat}},fg={{hi_hex}}'
setw -g copy-mode-match-style 'bg={{line_flat}},fg={{hi_hex}}'
setw -g copy-mode-current-match-style 'bg={{lineHi_flat}},fg={{solid_hex}}'
setw -g copy-mode-mark-style 'bg={{sel_flat}},fg={{hi_hex}}'
setw -g copy-mode-line-number-style 'fg={{dim_hex}}'
setw -g copy-mode-current-line-number-style 'fg={{hi_hex}}'
setw -g pane-scrollbars-style 'bg={{line_flat}},fg={{lineHi_flat}},width=1,pad=0'

setw -g popup-style 'bg=default,fg={{fg_hex}}'
setw -g popup-border-style 'fg={{lineHi_flat}}'
setw -g menu-style 'bg={{solid_hex}},fg={{fg_hex}}'
setw -g menu-selected-style 'bg={{sel_flat}},fg={{hi_hex}}'
setw -g menu-border-style 'fg={{lineHi_flat}}'

set -g display-panes-colour '{{dim_hex}}'
set -g display-panes-active-colour '{{hi_hex}}'
setw -g clock-mode-colour '{{hi_hex}}'
