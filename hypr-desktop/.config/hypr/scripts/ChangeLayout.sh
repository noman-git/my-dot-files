#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# for changing Hyprland Layouts (Master or Dwindle) on the fly

notif="$HOME/.config/swaync/images/ja.png"

LAYOUT=$(hyprctl -j getoption general:layout | jq '.str' | sed 's/"//g')

case $LAYOUT in
"master")
	hyprctl eval 'hl.config({ general = { layout = "dwindle" } })' >/dev/null
	# SUPER+J/K are global and managed by KeybindsLayoutInit.sh; only manage SUPER+O here
	hyprctl eval 'hl.bind("SUPER + O", hl.dsp.layout("togglesplit"), { description = "toggle split (dwindle)" })' >/dev/null
  notify-send -e -u low -i "$notif" " Dwindle Layout"
	;;
"dwindle")
	hyprctl eval 'hl.config({ general = { layout = "master" } })' >/dev/null
	# Drop togglesplit binding on SUPER+O when switching back to master
	hyprctl eval 'hl.unbind("SUPER + O")' >/dev/null
  notify-send -e -u low -i "$notif" " Master Layout"
	;;
*) ;;

esac
