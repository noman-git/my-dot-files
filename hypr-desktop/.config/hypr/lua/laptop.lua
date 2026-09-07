-- Laptop keys and the touchpad device.

local util = require("lua/util")

local mainMod = "SUPER"
local scripts = util.scripts

-- hyprctl devices gives the device name.
local touchpad = "asue1209:00-04f3:319f-touchpad"

hl.device({
    name = touchpad,
    enabled = true,
})

-- scripts/TouchPad.sh flips the enabled field above at runtime through
-- hyprctl eval. It used to set the $TOUCHPAD_ENABLED hyprlang variable,
-- which Lua configs do not have.

local function bind(keys, desc, dispatcher, flags)
    flags = flags or {}
    flags.description = desc
    return hl.bind(keys, dispatcher, flags)
end

bind("XF86KbdBrightnessDown", "decrease keyboard brightness",
    hl.dsp.exec_cmd(scripts .. "/BrightnessKbd.sh --dec"), { repeating = true })
bind("XF86KbdBrightnessUp", "increase keyboard brightness",
    hl.dsp.exec_cmd(scripts .. "/BrightnessKbd.sh --inc"), { repeating = true })
bind("XF86MonBrightnessDown", "decrease monitor brightness",
    hl.dsp.exec_cmd(scripts .. "/Brightness.sh --dec"), { repeating = true })
bind("XF86MonBrightnessUp", "increase monitor brightness",
    hl.dsp.exec_cmd(scripts .. "/Brightness.sh --inc"), { repeating = true })

bind("XF86Launch1", "ASUS Armory Crate button", hl.dsp.exec_cmd("rog-control-center"))
bind("XF86Launch3", "FN+F4 switch keyboard RGB profile", hl.dsp.exec_cmd("asusctl led-mode -n"))
bind("XF86Launch4", "FN+F5 change fan profile", hl.dsp.exec_cmd("asusctl profile -n"))
bind("XF86TouchpadToggle", "disable touchpad", hl.dsp.exec_cmd(scripts .. "/TouchPad.sh"))

-- Screenshots on F6, since this keyboard has no PrintScreen key.
bind(mainMod .. " + F6", "screenshot", hl.dsp.exec_cmd(scripts .. "/ScreenShot.sh --now"))
bind(mainMod .. " + SHIFT + F6", "screenshot (area)", hl.dsp.exec_cmd(scripts .. "/ScreenShot.sh --area"))
bind(mainMod .. " + CTRL + F6", "screenshot (5 secs delay)", hl.dsp.exec_cmd(scripts .. "/ScreenShot.sh --in5"))
bind(mainMod .. " + ALT + F6", "screenshot (10 secs delay)", hl.dsp.exec_cmd(scripts .. "/ScreenShot.sh --in10"))
bind("ALT + F6", "screenshot (active window only)", hl.dsp.exec_cmd(scripts .. "/ScreenShot.sh --active"))

-- Lid switch handling. Left off, as in the .conf version.
-- See https://wiki.hypr.land/configuring/core/binds/switches/
-- hl.bind("switch:off:Lid Switch", function()
--     hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })
-- end, { locked = true })
-- hl.bind("switch:on:Lid Switch", function()
--     hl.monitor({ output = "eDP-1", disabled = true })
-- end, { locked = true })
