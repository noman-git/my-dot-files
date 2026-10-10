#!/bin/sh
# Make every window of a session fit its client again.
#
#   fit-windows.sh <session>
#
# Layouts that tmux-resurrect restored keep their old pane size when the
# window grows (tmux 3.7c, 2026-10-10), and tmux fills the gap with dots.
# resize-window rebuilds the layout but sets window-size to manual, so the
# option is unset again right after.
for w in $(tmux list-windows -t "$1" -F '#{window_id}'); do
  tmux resize-window -t "$w" -A
  tmux set-option -uw -t "$w" window-size
done
