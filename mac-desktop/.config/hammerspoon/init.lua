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

-- One kitty process for every window, so OmniWM sees one app. `open -na`
-- started a new kitty process each time.
bind(mainMod, "return", "terminal", function()
    hs.task.new("/Applications/kitty.app/Contents/MacOS/kitty",
        nil, { "--single-instance", "--directory", os.getenv("HOME") }):start()
end)
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

-- Hyper (Caps Lock held, from Karabiner) + letter: focus the app, or open it.
local hyper = { "ctrl", "alt", "shift", "cmd" }
local apps = {
    t = "net.kovidgoyal.kitty",
    b = "app.zen-browser.zen",
    c = "com.google.Chrome",
    s = "com.tinyspeck.slackmacgap",
    d = "org.jkiss.dbeaver.core.product",
    m = "com.mongodb.compass",
    f = "com.apple.finder",
}
for key, id in pairs(apps) do
    bind(hyper, key, "focus " .. id, function() hs.application.launchOrFocusByBundleID(id) end)
end

hs.alert.show("Hammerspoon config loaded")
