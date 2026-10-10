#!/usr/bin/env bash
# Send omniwm_change to the bar on every OmniWM workspace or window change.
# The loop restarts the watcher when OmniWM is not up yet (at login
# SketchyBar starts first) or when OmniWM restarts.

while true; do
  omniwmctl watch active-workspace,windows-changed --reconnect \
    --exec sketchybar --trigger omniwm_change >/dev/null 2>&1
  sleep 2
done
