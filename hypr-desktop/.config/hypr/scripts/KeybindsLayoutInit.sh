#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Initialize J/K keybinds so they always cycle windows globally (no layout-specific behavior)
# This avoids double-actions when layouts change.

set -euo pipefail

# The config is Lua now, so binds are set with hyprctl eval rather than
# hyprctl keyword, which only works with the old hyprlang parser.

# Always reset and bind SUPER+J/K the same way on startup
hyprctl eval 'hl.unbind("SUPER + J")' >/dev/null || true
hyprctl eval 'hl.unbind("SUPER + K")' >/dev/null || true

# Cycle windows globally: J = next, K = previous
hyprctl eval 'hl.bind("SUPER + J", hl.dsp.window.cycle_next(), { description = "cycle next" })' >/dev/null
hyprctl eval 'hl.bind("SUPER + K", hl.dsp.window.cycle_next({ next = false }), { description = "cycle previous" })' >/dev/null
