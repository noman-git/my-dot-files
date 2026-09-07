#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For disabling touchpad.
# Edit the touchpad name in ~/.config/hypr/lua/laptop.lua according to your system
# use hyprctl devices to get your system touchpad device name
# source https://github.com/hyprwm/Hyprland/discussions/4283?sort=new#discussioncomment-8648109

notif="$HOME/.config/swaync/images/ja.png"

# Must match the name in ~/.config/hypr/lua/laptop.lua. hyprctl devices lists it.
TOUCHPAD="asue1209:00-04f3:319f-touchpad"

# The config is Lua now, so there is no $TOUCHPAD_ENABLED variable to set.
# hyprctl eval runs Lua against the running compositor instead.
set_touchpad() {
    hyprctl eval "hl.device({ name = \"$TOUCHPAD\", enabled = $1 })" >/dev/null
}

export STATUS_FILE="$XDG_RUNTIME_DIR/touchpad.status"

enable_touchpad() {
    printf "true" >"$STATUS_FILE"
    notify-send -u low -i $notif  " Enabling" " touchpad"
    set_touchpad true
}

disable_touchpad() {
    printf "false" >"$STATUS_FILE"
    notify-send -u low -i $notif " Disabling" " touchpad"
    set_touchpad false
}

if ! [ -f "$STATUS_FILE" ]; then
  enable_touchpad
else
  if [ $(cat "$STATUS_FILE") = "true" ]; then
    disable_touchpad
  elif [ $(cat "$STATUS_FILE") = "false" ]; then
    enable_touchpad
  fi
fi
