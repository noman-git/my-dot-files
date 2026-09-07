#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# searchable enabled keybinds using rofi
#
# The config is Lua now, so this no longer parses Keybinds.conf with awk.
# It asks the running compositor with "hyprctl binds -j" instead, which lists
# the binds that are actually active, descriptions included. That also picks up
# binds set at runtime by KeybindsLayoutInit.sh and ChangeLayout.sh.

# kill yad to not interfere with this binds
pkill yad || true

# check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

rofi_theme="$HOME/.config/rofi/config-keybinds.rasi"
msg='☣️ NOTE ☣️: Clicking with Mouse or Pressing ENTER will have NO function'

display_keybinds=$(hyprctl -j binds | python3 -c '
import json, sys

# Hyprland modmask bits.
MODS = [(64, "SUPER"), (4, "CTRL"), (8, "ALT"), (1, "SHIFT"),
        (2, "CAPS"), (16, "MOD2"), (32, "MOD3"), (128, "MOD5")]

def combo(b):
    parts = [name for bit, name in MODS if b.get("modmask", 0) & bit]
    key = str(b.get("key") or "")
    if not key and b.get("keycode"):
        key = "code:%s" % b["keycode"]
    if key:
        parts.append(key)
    return "+".join(parts)

def flags(b):
    out = []
    if b.get("locked"):    out.append("locked")
    if b.get("repeat"):    out.append("repeat")
    if b.get("mouse"):     out.append("mouse")
    if b.get("release"):   out.append("release")
    if b.get("longPress"): out.append("long-press")
    sub = b.get("submap") or ""
    if sub:
        out.append("submap:" + sub)
    return " [%s]" % ", ".join(out) if out else ""

try:
    binds = json.load(sys.stdin)
except Exception:
    sys.exit(1)

rows, seen = [], set()
for b in binds:
    c = combo(b)
    if not c:
        continue
    desc = (b.get("description") or "").strip()
    if not desc:
        # A Lua bind reports its dispatcher as "__lua", which says nothing
        # useful, so fall back to the dispatcher only when it is a real name.
        d = (b.get("dispatcher") or "").strip()
        arg = (b.get("arg") or "").strip()
        if d and d != "__lua":
            desc = d + ((" " + arg) if arg else "")
    line = "%s%s%s" % (c, flags(b), ("  —  " + desc) if desc else "")
    if line not in seen:
        seen.add(line)
        rows.append((c.lower(), line))

for _, line in sorted(rows):
    print(line)
')

# check for any keybinds to display
if [[ -z "$display_keybinds" ]]; then
    notify-send -u critical "Keybinds" "Could not read binds from hyprctl"
    echo "no keybinds found."
    exit 1
fi

count=$(printf '%s\n' "$display_keybinds" | grep -c '')
msg="$msg | $count active binds"

# use rofi to display the keybinds
printf '%s\n' "$display_keybinds" | rofi -dmenu -i -config "$rofi_theme" -mesg "$msg"
