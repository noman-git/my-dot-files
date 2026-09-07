#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For applying Animations from different users

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

# Variables
iDIR="$HOME/.config/swaync/images"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
# The config is Lua now, so the presets live in animations-lua/ as .lua files
# and the active one is lua/animations.lua. The old animations/*.conf presets
# are kept for reference but are no longer read by Hyprland.
animations_dir="$HOME/.config/hypr/animations-lua"
lua_dir="$HOME/.config/hypr/lua"
rofi_theme="$HOME/.config/rofi/config-Animations.rasi"
msg='❗NOTE:❗ This will copy animations into lua/animations.lua'
# list of animation files, sorted alphabetically with numbers first
animations_list=$(find -L "$animations_dir" -maxdepth 1 -type f -name '*.lua' | sed 's/.*\///' | sed 's/\.lua$//' | sort -V)

# Rofi Menu
chosen_file=$(echo "$animations_list" | rofi -i -dmenu -config $rofi_theme -mesg "$msg")

# Check if a file was selected
if [[ -n "$chosen_file" ]]; then
    full_path="$animations_dir/$chosen_file.lua"
    if Hyprland --verify-config -c "$full_path" 2>&1 | grep -q "^config ok"; then
        cp "$full_path" "$lua_dir/animations.lua"
        notify-send -u low -i "$iDIR/ja.png" "$chosen_file" "Hyprland Animation Loaded"
    else
        notify-send -u critical -i "$iDIR/error.png" "$chosen_file" "Preset has errors, not applied"
        exit 1
    fi
fi

sleep 1
"$SCRIPTSDIR/RefreshNoWaybar.sh"
