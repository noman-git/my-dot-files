#!/usr/bin/env bash
# NordVPN rofi picker — searchable replacement for the overflowing tray menu.
# Bound to $mainMod SHIFT, V in UserKeybinds.conf
set -uo pipefail

# rofi 2.0 ignores listview columns:1 in some sessions and grids the list to fill
# width; config-nordvpn.rasi pins a narrow fixed width so only one column fits.
RCONF="$HOME/.config/rofi/config-nordvpn.rasi"
BEST="🎯  Best available"

menu() { rofi -dmenu -i -p "$1" -config "$RCONF"; }
msg()  { rofi -e "$1"; }                # transient message (no notify-send on this box)

# The nordvpn CLI formats lists into a space-padded multi-column grid depending on
# the detected terminal width — so output may be one-per-line OR many-per-line.
# Tokens themselves never contain spaces (they use underscores), so we can always
# split on whitespace to get one entry per line, then show underscores as spaces.
listify() { tr -s '[:space:]' '\n' | grep -av '^$' | sed 's/_/ /g' | sort; }

# Underscore tokens are what `nordvpn connect` expects; we show spaces and convert back.
to_token() { printf '%s' "${1// /_}"; }

do_connect() {
    out=$(nordvpn connect "$@" 2>&1)
    last=$(printf '%s\n' "$out" | grep -aiE 'connected|connecting|not|error|fail|whoops|exist' | tail -1)
    msg "${last:-$out}"
}

status=$(nordvpn status 2>/dev/null | awk -F': ' '/^Status/{print $2}')

# ---- main menu ----
main="⚡  Quick Connect"
[ "$status" = "Connected" ] && main+=$'\n'"✖  Disconnect"
main+=$'\n'"🌐  Groups"$'\n'"────────────"
main+=$'\n'"$(nordvpn countries | listify)"

choice=$(printf '%s' "$main" | menu "NordVPN")
[ -z "$choice" ] && exit 0

case "$choice" in
    "⚡  Quick Connect") do_connect ; exit 0 ;;
    "✖  Disconnect")    msg "$(nordvpn disconnect 2>&1 | tail -1)" ; exit 0 ;;
    "────────────")     exit 0 ;;
    "🌐  Groups")
        grp=$(nordvpn groups | listify | menu "Group")
        [ -z "$grp" ] && exit 0
        do_connect "$(to_token "$grp")" ; exit 0 ;;
esac

# ---- a country was chosen ----
country=$(to_token "$choice")

# City-less countries print an error sentence instead of city tokens. Detect that by
# keyword (can't rely on spaces — gridded city output also has spaces) and just connect
# to the country in that case.
cities_raw=$(nordvpn cities "$country" 2>&1)
if [ $? -ne 0 ] || [ -z "$cities_raw" ] || \
   printf '%s' "$cities_raw" | grep -qiE 'not available|servers by|could|whoops|sorry|no servers|error'; then
    do_connect "$country" ; exit 0
fi

cities=$(printf '%s' "$cities_raw" | listify)
# City-state (e.g. Singapore): the only "city" equals the country → "connect Singapore
# Singapore" fails, so just connect to the country.
if [ "$cities" = "$choice" ] || [ "$cities" = "$country" ]; then
    do_connect "$country" ; exit 0
fi

city=$(printf '%s\n%s' "$BEST" "$cities" | menu "$choice")
[ -z "$city" ] && exit 0
if [ "$city" = "$BEST" ]; then
    do_connect "$country"
else
    do_connect "$country" "$(to_token "$city")"
fi
