#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Game Mode. Turning off all animations

notif="$HOME/.config/swaync/images/ja.png"
SCRIPTSDIR="$HOME/.config/hypr/scripts"


# Under the Lua config animations:enabled reports as a bool, not an int, so
# read the JSON and normalise to 1/0 rather than awk-ing the plain output.
HYPRGAMEMODE=$(hyprctl -j getoption animations:enabled \
    | jq -r 'if .bool != null then (if .bool then 1 else 0 end) elif .int != null then .int else 0 end')
if [ "$HYPRGAMEMODE" = 1 ] ; then
    # hyprctl keyword does not work with the Lua parser; one eval sets it all.
    hyprctl eval '
        hl.config({
            animations = { enabled = false },
            decoration = { shadow = { enabled = false }, blur = { enabled = false }, rounding = 0 },
            general    = { gaps_in = 0, gaps_out = 0, border_size = 1 },
        })
        hl.window_rule({
            name    = "gamemode-opacity",
            match   = { class = ".*" },
            opacity = "1 override 1 override 1 override",
        })
    ' >/dev/null
    swww kill 
    notify-send -e -u low -i "$notif" " Gamemode:" " enabled"
    sleep 0.1
    exit
else
	swww-daemon --format xrgb && swww img "$HOME/.config/rofi/.current_wallpaper" &
	sleep 0.1
	${SCRIPTSDIR}/WallustSwww.sh
	sleep 0.5
  hyprctl reload
	${SCRIPTSDIR}/Refresh.sh	 
    notify-send -e -u normal -i "$notif" " Gamemode:" " disabled"
    exit
fi
hyprctl reload
