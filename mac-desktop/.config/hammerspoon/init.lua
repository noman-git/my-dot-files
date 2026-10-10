-- App and system binds that OmniWM cannot run itself. OmniWM owns the window
-- binds (~/.config/omniwm/settings.toml). mainMod is Option, the key in the
-- SUPER position on a Mac keyboard, the same as the OmniWM binds.
--
-- install_mac.sh points Hammerspoon at this file with
--   defaults write org.hammerspoon.Hammerspoon MJConfigFile ~/.config/hammerspoon/init.lua

local mainMod = { "alt" }

local function sh(cmd)
    return function() hs.execute(cmd, true) end
end

-- Send a key chord after the mainMod key is released, so Option is not added
-- to the chord.
local function keys(mods, key)
    return function() hs.eventtap.keyStroke(mods, key, 0) end
end

local function bind(mods, key, desc, fn)
    hs.hotkey.bind(mods, key, desc, nil, fn)
end

bind(mainMod, "return", "terminal", sh("open -na kitty"))
bind(mainMod, "e", "file manager", sh("open ~"))
bind(mainMod, "b", "default browser", function()
    local id = hs.urlevent.getDefaultHandler("https")
    if id then hs.application.launchOrFocusByBundleID(id) end
end)

-- Launcher: Cmd+Space opens Spotlight, or Raycast if Raycast took that key.
bind(mainMod, "d", "app launcher", keys({ "cmd" }, "space"))

-- Screenshot toolbar (area, window, screen, recording).
bind({ "alt", "shift" }, "s", "screenshot", keys({ "cmd", "shift" }, "5"))

bind({ "ctrl", "alt" }, "l", "lock screen", hs.caffeinate.lockScreen)

bind({ "alt", "ctrl", "shift" }, "r", "reload hammerspoon", hs.reload)

hs.alert.show("Hammerspoon config loaded")
