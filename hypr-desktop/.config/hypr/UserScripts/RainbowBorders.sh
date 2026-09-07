#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# for rainbow borders animation

function random_hex() {
    random_hex=("0xff$(openssl rand -hex 3)")
    echo $random_hex
}

# A Lua gradient is { colors = {...}, angle = N }, so build the colour list and
# feed it to hyprctl eval. hyprctl keyword does not work with the Lua parser.
function gradient() {
    local colors=""
    for _ in $(seq 1 10); do
        colors+="\"$(random_hex)\", "
    done
    printf '{ colors = { %s }, angle = 270 }' "${colors%, }"
}

# rainbow colors only for active window
hyprctl eval "hl.config({ general = { col = { active_border = $(gradient) } } })" >/dev/null

# rainbow colors for inactive window (uncomment to take effect)
#hyprctl eval "hl.config({ general = { col = { inactive_border = $(gradient) } } })" >/dev/null