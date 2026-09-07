-- Default keybinds.
-- See https://wiki.hypr.land/configuring/core/binds/

local util = require("lua/util")
local apps = require("lua/defaults")

local mainMod = "SUPER"
local scripts = util.scripts
local userScripts = util.userScripts

-- hl.bind(keys, dispatcher, { description = ... }). The old bindd/bindl/binde
-- letter suffixes are now named flags: l = locked, e = repeating,
-- m = mouse, n = non_consuming, d = description.
local function bind(keys, desc, dispatcher, flags)
    flags = flags or {}
    flags.description = desc
    return hl.bind(keys, dispatcher, flags)
end

local function exec(cmd)
    return hl.dsp.exec_cmd(cmd)
end

--------------------------------------------------------------------------
-- Common shortcuts
--------------------------------------------------------------------------
bind(mainMod .. " + D", "app launcher",
    exec("pkill rofi || true && rofi -show drun -modi drun,filebrowser,run,window"))
bind(mainMod .. " + B", "open default browser", exec('xdg-open "https://"'))
-- Toggles the quickshell or ags overview (tries QS first, falls back to AGS).
bind(mainMod .. " + A", "desktop overview", exec(scripts .. "/OverviewToggle.sh"))
bind(mainMod .. " + Return", "Open terminal", exec(apps.term))
bind(mainMod .. " + E", "file manager", exec(apps.files))

--------------------------------------------------------------------------
-- Features / extras
--------------------------------------------------------------------------
bind(mainMod .. " + H", "help / cheat sheet", exec(scripts .. "/KeyHints.sh"))
bind(mainMod .. " + ALT + R", "refresh bar and menus", exec(scripts .. "/Refresh.sh"))
bind(mainMod .. " + ALT + E", "emoji menu", exec(scripts .. "/RofiEmoji.sh"))
bind(mainMod .. " + S", "web search", exec(scripts .. "/RofiSearch.sh"))
bind(mainMod .. " + CTRL + S", "window switcher", exec("rofi -show window"))
bind(mainMod .. " + ALT + O", "toggle blur", exec(scripts .. "/ChangeBlur.sh"))
bind(mainMod .. " + SHIFT + G", "toggle game mode", exec(scripts .. "/GameMode.sh"))
bind(mainMod .. " + ALT + L", "toggle master/dwindle layout", exec(scripts .. "/ChangeLayout.sh"))
bind(mainMod .. " + ALT + V", "clipboard manager", exec(scripts .. "/ClipManager.sh"))
bind(mainMod .. " + CTRL + R", "rofi theme selector", exec(scripts .. "/RofiThemeSelector.sh"))
bind(mainMod .. " + CTRL + SHIFT + R", "rofi theme selector (modified)",
    exec("pkill rofi || true && " .. scripts .. "/RofiThemeSelector-modified.sh"))

bind(mainMod .. " + SHIFT + F", "fullscreen", hl.dsp.window.fullscreen())
bind(mainMod .. " + CTRL + F", "maximize window", hl.dsp.window.fullscreen({ mode = "maximized" }))
bind(mainMod .. " + SPACE", "Float current window", hl.dsp.window.float())

-- "workspaceopt allfloat" has no Lua dispatcher, so float each window in turn.
bind(mainMod .. " + ALT + SPACE", "Float all windows", function()
    local ws = hl.get_active_workspace()
    if not ws then
        return
    end
    for _, w in ipairs(ws:get_windows()) do
        hl.dispatch(hl.dsp.window.float({ window = "address:" .. w.address, action = "toggle" }))
    end
end)

bind(mainMod .. " + SHIFT + Return", "DropDown terminal",
    exec(scripts .. "/Dropterminal.sh " .. apps.term))

-- Desktop zoom. This was a hyprctl keyword + awk pipeline; now native Lua.
bind(mainMod .. " + ALT + mouse_down", "zoom in", util.zoom(2.0))
bind(mainMod .. " + ALT + mouse_up", "zoom out", util.zoom(1 / 2.0))

--------------------------------------------------------------------------
-- Waybar
--------------------------------------------------------------------------
bind(mainMod .. " + CTRL + ALT + B", "toggle waybar on/off", exec("pkill -SIGUSR1 waybar"))
bind(mainMod .. " + CTRL + B", "waybar styles menu", exec(scripts .. "/WaybarStyles.sh"))
bind(mainMod .. " + ALT + B", "waybar layout menu", exec(scripts .. "/WaybarLayout.sh"))

bind(mainMod .. " + N", "toggle night light", exec(scripts .. "/Hyprsunset.sh toggle"))

--------------------------------------------------------------------------
-- UserScripts
--------------------------------------------------------------------------
bind(mainMod .. " + SHIFT + M", "online music", exec(userScripts .. "/RofiBeats.sh"))
bind(mainMod .. " + W", "select wallpaper", exec(userScripts .. "/WallpaperSelect.sh"))
bind(mainMod .. " + SHIFT + W", "wallpaper effects", exec(userScripts .. "/WallpaperEffects.sh"))
bind("CTRL + ALT + W", "random wallpaper", exec(userScripts .. "/WallpaperRandom.sh"))
bind(mainMod .. " + CTRL + O", "toggle active window opacity",
    hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" }))
bind(mainMod .. " + SHIFT + K", "search keybinds", exec(scripts .. "/KeyBinds.sh"))
bind(mainMod .. " + SHIFT + A", "animations menu", exec(scripts .. "/Animations.sh"))
bind(mainMod .. " + SHIFT + O", "change oh-my-zsh theme", exec(userScripts .. "/ZshChangeTheme.sh"))
-- The .conf wrote these as "ALT_L, SHIFT_L" and "SHIFT_L, ALT_L", where the
-- first field was the modifier. hyprlang read ALT_L as the ALT modifier and
-- SHIFT_L as SHIFT, so they are spelled that way here to keep the same modmask.
bind("ALT + Shift_L", "switch keyboard layout globally",
    exec(scripts .. "/SwitchKeyboardLayout.sh"), { locked = true, non_consuming = true })
bind("SHIFT + Alt_L", "switch keyboard layout per-window",
    exec(scripts .. "/Tak0-Per-Window-Switch.sh"), { locked = true, non_consuming = true })
bind(mainMod .. " + ALT + C", "calculator", exec(userScripts .. "/RofiCalc.sh"))

--------------------------------------------------------------------------
-- Move the current workspace between monitors
--------------------------------------------------------------------------
bind(mainMod .. " + CTRL + F9", "move workspace to left monitor", hl.dsp.workspace.move({ monitor = "l" }))
bind(mainMod .. " + CTRL + F10", "move workspace to right monitor", hl.dsp.workspace.move({ monitor = "r" }))
bind(mainMod .. " + CTRL + F11", "move workspace to up monitor", hl.dsp.workspace.move({ monitor = "u" }))
bind(mainMod .. " + CTRL + F12", "move workspace to down monitor", hl.dsp.workspace.move({ monitor = "d" }))

--------------------------------------------------------------------------
-- System
--------------------------------------------------------------------------
bind("CTRL + ALT + Delete", "exit Hyprland", hl.dsp.exit())
bind(mainMod .. " + Q", "close active window", hl.dsp.window.close())
bind(mainMod .. " + SHIFT + Q", "Terminate active process", exec(scripts .. "/KillActiveProcess.sh"))
bind("CTRL + ALT + L", "lock screen", exec(scripts .. "/LockScreen.sh"))
bind("CTRL + ALT + P", "powermenu", exec(scripts .. "/Wlogout.sh"))
bind(mainMod .. " + SHIFT + N", "notification panel", exec("swaync-client -t -sw"))
bind(mainMod .. " + SHIFT + E", "Quick settings menu", exec(scripts .. "/Kool_Quick_Settings.sh"))

--------------------------------------------------------------------------
-- Master layout
--------------------------------------------------------------------------
bind(mainMod .. " + CTRL + D", "remove master", hl.dsp.layout("removemaster"))
bind(mainMod .. " + I", "add master", hl.dsp.layout("addmaster"))
-- The J/K binds are set at runtime by scripts/KeybindsLayoutInit.sh and
-- scripts/ChangeLayout.sh, so they are deliberately not bound here.
bind(mainMod .. " + CTRL + Return", "swap with master", hl.dsp.layout("swapwithmaster"))

--------------------------------------------------------------------------
-- Dwindle layout
--------------------------------------------------------------------------
bind(mainMod .. " + SHIFT + I", "toggle split (dwindle)", hl.dsp.layout("togglesplit"))
bind(mainMod .. " + P", "toggle pseudo (dwindle)", hl.dsp.window.pseudo())

-- Works on either layout.
bind(mainMod .. " + M", "set split ratio 0.3", hl.dsp.layout("splitratio 0.3"))

--------------------------------------------------------------------------
-- Cycle windows, bringing floating ones to the top
--------------------------------------------------------------------------
bind("ALT + tab", "cycle next window", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

--------------------------------------------------------------------------
-- Hardware keys
--------------------------------------------------------------------------
bind("XF86AudioRaiseVolume", "volume up", exec(scripts .. "/Volume.sh --inc"),
    { repeating = true, locked = true })
bind("XF86AudioLowerVolume", "volume down", exec(scripts .. "/Volume.sh --dec"),
    { repeating = true, locked = true })
bind("XF86AudioMicMute", "toggle mic mute", exec(scripts .. "/Volume.sh --toggle-mic"), { locked = true })
bind("XF86AudioMute", "toggle mute", exec(scripts .. "/Volume.sh --toggle"), { locked = true })
bind("XF86Sleep", "sleep", exec("systemctl suspend"), { locked = true })
bind("XF86Rfkill", "airplane mode", exec(scripts .. "/AirplaneMode.sh"), { locked = true })

-- The .conf bound xf86AudioPlayPause, which is not a real keysym, so that
-- bind never fired. KEY_PLAYPAUSE is XF86MediaPlayPause.
bind("XF86MediaPlayPause", "play/pause", exec(scripts .. "/MediaCtrl.sh --pause"), { locked = true })
bind("XF86AudioPause", "pause", exec(scripts .. "/MediaCtrl.sh --pause"), { locked = true })
bind("XF86AudioPlay", "play", exec(scripts .. "/MediaCtrl.sh --pause"), { locked = true })
bind("XF86AudioNext", "next track", exec(scripts .. "/MediaCtrl.sh --nxt"), { locked = true })
bind("XF86AudioPrev", "previous track", exec(scripts .. "/MediaCtrl.sh --prv"), { locked = true })
bind("XF86AudioStop", "stop", exec(scripts .. "/MediaCtrl.sh --stop"), { locked = true })

--------------------------------------------------------------------------
-- Screenshots. You may need to hold Fn as well.
--------------------------------------------------------------------------
bind(mainMod .. " + Print", "screenshot now", exec(scripts .. "/ScreenShot.sh --now"))
bind(mainMod .. " + SHIFT + Print", "screenshot (area)", exec(scripts .. "/ScreenShot.sh --area"))
bind(mainMod .. " + CTRL + Print", "screenshot in 5s", exec(scripts .. "/ScreenShot.sh --in5"))
bind(mainMod .. " + CTRL + SHIFT + Print", "screenshot in 10s", exec(scripts .. "/ScreenShot.sh --in10"))
bind("ALT + Print", "screenshot active window", exec(scripts .. "/ScreenShot.sh --active"))
bind(mainMod .. " + SHIFT + S", "screenshot (swappy)", exec(scripts .. "/ScreenShot.sh --swappy"))

--------------------------------------------------------------------------
-- Resize windows
--------------------------------------------------------------------------
bind(mainMod .. " + SHIFT + left", "resize left (-50)",
    hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
bind(mainMod .. " + SHIFT + right", "resize right (+50)",
    hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
bind(mainMod .. " + SHIFT + up", "resize up (-50)",
    hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
bind(mainMod .. " + SHIFT + down", "resize down (+50)",
    hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })

--------------------------------------------------------------------------
-- Move, swap and focus
--------------------------------------------------------------------------
local directions = { left = "l", right = "r", up = "u", down = "d" }
for key, _ in pairs(directions) do
    bind(mainMod .. " + CTRL + " .. key, "move window " .. key, hl.dsp.window.move({ direction = key }))
    bind(mainMod .. " + ALT + " .. key, "swap window " .. key, hl.dsp.window.swap({ direction = key }))
    bind(mainMod .. " + " .. key, "focus " .. key, hl.dsp.focus({ direction = key }))
end

--------------------------------------------------------------------------
-- Groups
--------------------------------------------------------------------------
bind(mainMod .. " + G", "toggle group", hl.dsp.group.toggle())
bind(mainMod .. " + Tab", "Change Group Forward", hl.dsp.group.next())
bind(mainMod .. " + CTRL + tab", "change active in group", hl.dsp.group.next())
bind(mainMod .. " + SHIFT + Tab", "Change Group Back", hl.dsp.group.prev())
bind(mainMod .. " + CTRL + K", "Move left into group", hl.dsp.window.move({ into_group = "left" }))
bind(mainMod .. " + CTRL + L", "Move Right into group", hl.dsp.window.move({ into_group = "right" }))
bind(mainMod .. " + CTRL + H", "Move active out of group", hl.dsp.window.move({ out_of_group = true }))

--------------------------------------------------------------------------
-- Workspaces
--------------------------------------------------------------------------
bind(mainMod .. " + tab", "next workspace", hl.dsp.focus({ workspace = "m+1" }))
bind(mainMod .. " + SHIFT + tab", "previous workspace", hl.dsp.focus({ workspace = "m-1" }))

bind(mainMod .. " + SHIFT + U", "move to special workspace",
    hl.dsp.window.move({ workspace = "special", follow = true }))
bind(mainMod .. " + U", "toggle special workspace", hl.dsp.workspace.toggle_special(""))

-- The .conf bound these by keycode (code:10 is key 1 ... code:19 is key 0) to
-- survive a keyboard layout change. Hyprland 0.56.2 accepts "code:NN" in a Lua
-- bind string without complaining but registers keycode 0, so those binds would
-- be dead. Digits are used instead, which is what Hyprland's own example Lua
-- config does. This layout is us only (input.kb_layout in lua/settings.lua), so
-- the digits sit where the keycodes did. Recheck "code:NN" after a Hyprland
-- upgrade if you ever add a layout where the digit row differs.
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    bind(mainMod .. " + " .. key, "workspace " .. i, hl.dsp.focus({ workspace = i }))
    bind(mainMod .. " + SHIFT + " .. key, "move to workspace " .. i,
        hl.dsp.window.move({ workspace = i, follow = true }))
    bind(mainMod .. " + CTRL + " .. key, "move silently to workspace " .. i,
        hl.dsp.window.move({ workspace = i, follow = false }))
end

bind(mainMod .. " + SHIFT + bracketleft", "move to previous workspace",
    hl.dsp.window.move({ workspace = "-1", follow = true }))
bind(mainMod .. " + SHIFT + bracketright", "move to next workspace",
    hl.dsp.window.move({ workspace = "+1", follow = true }))
bind(mainMod .. " + CTRL + bracketleft", "move silently to previous workspace",
    hl.dsp.window.move({ workspace = "-1", follow = false }))
bind(mainMod .. " + CTRL + bracketright", "move silently to next workspace",
    hl.dsp.window.move({ workspace = "+1", follow = false }))

bind(mainMod .. " + mouse_down", "next workspace", hl.dsp.focus({ workspace = "e+1" }))
bind(mainMod .. " + mouse_up", "previous workspace", hl.dsp.focus({ workspace = "e-1" }))
bind(mainMod .. " + period", "next workspace", hl.dsp.focus({ workspace = "e+1" }))
bind(mainMod .. " + comma", "previous workspace", hl.dsp.focus({ workspace = "e-1" }))

--------------------------------------------------------------------------
-- Mouse binds. mouse:272 is left click, mouse:273 is right click.
--
-- NOTE: on 0.56.2 "hyprctl binds" reports mouse=false for these and no Lua
-- flag sets that bit, but both binds were tested on 2026-09-03 and drag and
-- resize work anyway, so the flag is vestigial: drag and resize are
-- interactive by nature now. It is kept because Hyprland's own shipped example
-- config at /usr/share/hypr/hyprland.lua passes it too. Do not go chasing
-- mouse=false in hyprctl output; it does not mean these binds are broken.
--------------------------------------------------------------------------
bind(mainMod .. " + mouse:272", "move window", hl.dsp.window.drag(), { mouse = true })
bind(mainMod .. " + mouse:273", "resize window", hl.dsp.window.resize(), { mouse = true })
