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

-- Run fn once every modifier is up. Firefox-based browsers like Zen open
-- Troubleshoot Mode when Option or Shift is down at launch.
local function whenModifiersUp(fn)
    return function()
        hs.timer.waitUntil(function()
            return next(hs.eventtap.checkKeyboardModifiers()) == nil
        end, fn, 0.02)
    end
end

-- hs.hotkey.bind shifts its arguments when the message is not a string, so
-- (mods, key, nil, fn) makes fn the released function. A string message
-- shows an alert on every press, so no message is passed.
local function bind(mods, key, desc, fn)
    hs.hotkey.bind(mods, key, nil, fn)
end

-- One kitty process for every window, so OmniWM sees one app. `open -na`
-- started a new kitty process each time.
bind(mainMod, "return", "terminal", function()
    hs.task.new("/Applications/kitty.app/Contents/MacOS/kitty",
        nil, { "--single-instance", "--directory", os.getenv("HOME") }):start()
end)
bind(mainMod, "e", "file manager", sh("open ~"))
bind(mainMod, "b", "default browser", whenModifiersUp(function()
    local id = hs.urlevent.getDefaultHandler("https")
    if id then hs.application.launchOrFocusByBundleID(id) end
end))

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
    bind(hyper, key, "focus " .. id, whenModifiersUp(function()
        hs.application.launchOrFocusByBundleID(id)
    end))
end

hs.alert.show("Hammerspoon config loaded")

-- Wi-Fi menu for SketchyBar. Network names need Location access, which only
-- an app can get, so the bar asks Hammerspoon through hammerspoon:// URLs:
--   hammerspoon://wifi-menu          scan and fill the wifi popup
--   hammerspoon://wifi-join?ssid=X   join X (saved: no password; new: prompt)
local SKETCHYBAR = "/opt/homebrew/bin/sketchybar"

local function sketchybar(args)
    hs.task.new(SKETCHYBAR, nil, args):start()
end

local function savedNetworks()
    local out = hs.execute("networksetup -listpreferredwirelessnetworks en0") or ""
    local saved = {}
    for line in out:gmatch("[^\n]+") do
        local name = line:match("^\t(.+)$")
        if name then saved[name] = true end
    end
    return saved
end

-- Fill the menu slots wifi.net.1-12 that sketchybarrc makes; hide the rest.
local WIFI_SLOTS = 12
local function fillWifiMenu(names, current)
    local saved = savedNetworks()
    local args = {}
    local function add(...) for _, a in ipairs({ ... }) do table.insert(args, a) end end
    for i = 1, WIFI_SLOTS do
        local item, name = "wifi.net." .. i, names[i]
        if name then
            local icon = "󰖩"
            if name == current then icon = "󰄬" elseif saved[name] then icon = "󰤨" end
            local url = "hammerspoon://wifi-join?ssid=" .. hs.http.encodeForQuery(name)
            add("--set", item, "drawing=on", "icon=" .. icon, "label=" .. name,
                "click_script=open -g '" .. url .. "'; " .. SKETCHYBAR .. " --set wifi popup.drawing=off")
        else
            add("--set", item, "drawing=off")
        end
    end
    sketchybar(args)
end

-- Network names, current first, then strongest, at most WIFI_SLOTS. Without
-- Location access the names are hidden, so it falls back to the saved ones.
local function networkNames(networks, current)
    local seen, names = {}, {}
    if current then
        seen[current] = true
        table.insert(names, current)
    end
    table.sort(networks, function(a, b) return (a.rssi or -100) > (b.rssi or -100) end)
    for _, n in ipairs(networks) do
        local name = n.ssid
        if name and name ~= "" and not seen[name] and #names < WIFI_SLOTS then
            seen[name] = true
            table.insert(names, name)
        end
    end
    if #names == 0 then
        for name in pairs(savedNetworks()) do table.insert(names, name) end
        table.sort(names)
    end
    return names
end

local function cachedNetworks()
    return (hs.wifi.interfaceDetails() or {}).cachedScanResults or {}
end

-- Show the last scan at once, then the new scan when it is done.
local wifiScan
hs.urlevent.bind("wifi-menu", function()
    local current = hs.wifi.currentNetwork()
    local cached = cachedNetworks()
    if #cached > 0 then
        fillWifiMenu(networkNames(cached, current), current)
    else
        fillWifiMenu({ "Scanning…" }, nil)
    end
    wifiScan = hs.wifi.backgroundScan(function(networks)
        -- On an error the callback gets a string; use the cached scan then.
        if type(networks) ~= "table" then networks = cachedNetworks() end
        fillWifiMenu(networkNames(networks, current), current)
    end)
end)

hs.urlevent.bind("wifi-join", function(_, params)
    local ssid = params.ssid
    if not ssid or ssid == "Scanning…" then return end
    if savedNetworks()[ssid] then
        local out = hs.execute("networksetup -setairportnetwork en0 '" .. ssid:gsub("'", "'\\''") .. "'") or ""
        if out == "" then
            hs.alert.show("Joined " .. ssid)
            return
        end
    end
    local button, password = hs.dialog.textPrompt("Join " .. ssid, "Wi-Fi password", "", "Join", "Cancel", true)
    if button ~= "Join" then return end
    if hs.wifi.associate(ssid, password) then
        hs.alert.show("Joined " .. ssid)
    else
        hs.alert.show("Could not join " .. ssid)
    end
end)

-- Ask for Location access, so the scan can read network names. macOS adds
-- Hammerspoon to Privacy & Security > Location Services only after this.
--   hammerspoon://location-request   ask again and write the status to
--                                    ~/.cache/hammerspoon-location
local function requestLocation()
    hs.location.start()
    hs.timer.doAfter(10, function()
        hs.location.stop()
        local f = io.open(os.getenv("HOME") .. "/.cache/hammerspoon-location", "w")
        if f then
            f:write(tostring(hs.location.servicesEnabled()), " ", hs.location.authorizationStatus(), "\n")
            f:close()
        end
    end)
end
hs.urlevent.bind("location-request", requestLocation)
if hs.location.authorizationStatus() == "undetermined" then requestLocation() end

-- hammerspoon://notification-center opens the Notification Center for the
-- bar. It sends Hyper+N, the "Show Notification Center" shortcut that
-- install_mac.sh turns on (symbolic hotkey 163; macOS has no command for it).
hs.urlevent.bind("notification-center", function()
    hs.eventtap.keyStroke(hyper, "n", 0)
end)

-- Wallpaper picker, like WallpaperSelect.sh and WallpaperRandom.sh on Arch.
-- Images come from ~/Pictures/wallpapers (all subfolders); thumbnails are
-- cached in ~/.cache/wallpaper-thumbs. A pick runs mac-wallpaper, which
-- sets the wallpaper and recolours the bar with wallust.
local WALLPAPER_DIR = os.getenv("HOME") .. "/Pictures/wallpapers"
local THUMB_DIR = os.getenv("HOME") .. "/.cache/wallpaper-thumbs"
local MAC_WALLPAPER = os.getenv("HOME") .. "/.local/bin/mac-wallpaper"

local function wallpapers()
    local out = hs.execute("find '" .. WALLPAPER_DIR .. "' -type f \\( -iname '*.jpg' -o -iname '*.jpeg'"
        .. " -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null | sort") or ""
    local files = {}
    for path in out:gmatch("[^\n]+") do table.insert(files, path) end
    return files
end

local function thumbPath(path)
    return THUMB_DIR .. "/" .. hs.hash.MD5(path) .. ".jpg"
end

local function setWallpaper(path)
    hs.task.new(MAC_WALLPAPER, function(code, _, err)
        if code ~= 0 then hs.alert.show("mac-wallpaper failed: " .. (err or "")) end
    end, { path }):start()
end

-- Make the missing thumbnails in the background with sips.
local thumbTask
local function makeThumbs(files)
    local missing = {}
    for _, path in ipairs(files) do
        if not hs.fs.attributes(thumbPath(path)) then
            table.insert(missing, string.format("sips -s format jpeg -Z 240 %q --out %q >/dev/null 2>&1",
                path, thumbPath(path)))
        end
    end
    if #missing == 0 or (thumbTask and thumbTask:isRunning()) then return end
    hs.fs.mkdir(THUMB_DIR)
    thumbTask = hs.task.new("/bin/sh", nil, { "-c", table.concat(missing, "; ") })
    thumbTask:start()
end

local wallpaperChooser = hs.chooser.new(function(choice)
    if choice then setWallpaper(choice.path) end
end)
wallpaperChooser:placeholderText("Wallpaper")
wallpaperChooser:rows(8)

bind(mainMod, "w", "wallpaper picker", function()
    local files = wallpapers()
    if #files == 0 then
        hs.alert.show("No images in " .. WALLPAPER_DIR)
        return
    end
    makeThumbs(files)
    local choices = {}
    for _, path in ipairs(files) do
        local thumb = thumbPath(path)
        table.insert(choices, {
            text = path:match("([^/]+)$"),
            subText = path:sub(#WALLPAPER_DIR + 2):match("(.*)/") or "",
            path = path,
            image = hs.fs.attributes(thumb) and hs.image.imageFromPath(thumb) or nil,
        })
    end
    wallpaperChooser:choices(choices)
    wallpaperChooser:show()
end)

bind({ "ctrl", "alt" }, "w", "random wallpaper", function()
    local files = wallpapers()
    if #files == 0 then
        hs.alert.show("No images in " .. WALLPAPER_DIR)
        return
    end
    setWallpaper(files[math.random(#files)])
end)

-- Launcher tools on the Arch rofi keys (ALT on Arch is Command here).
-- Raycast keeps its own hotkeys in an encrypted database, so the keys live
-- here and open Raycast commands by deeplink.
local function raycast(command)
    return whenModifiersUp(function() hs.execute("open -g 'raycast://extensions/raycast/" .. command .. "'") end)
end
bind({ "alt", "cmd" }, "e", "emoji", raycast("emoji-symbols/search-emoji-symbols"))
bind({ "alt", "cmd" }, "v", "clipboard history", raycast("clipboard-history/clipboard-history"))
bind({ "alt", "ctrl" }, "s", "window switcher", raycast("navigation/switch-windows"))
-- Raycast's root search calculates as you type.
bind({ "alt", "cmd" }, "c", "calculator", keys({ "cmd" }, "space"))

-- Web search, like RofiSearch.sh: type a query, Enter opens the browser.
local searchChooser
searchChooser = hs.chooser.new(function(choice)
    if choice then
        hs.urlevent.openURL("https://www.google.com/search?q=" .. hs.http.encodeForQuery(choice.query))
    end
end)
searchChooser:placeholderText("Search Google")
searchChooser:queryChangedCallback(function(query)
    if query == "" then
        searchChooser:choices({})
    else
        searchChooser:choices({ { text = "Search Google for \"" .. query .. "\"", query = query } })
    end
end)
bind(mainMod, "s", "web search", function()
    searchChooser:query("")
    searchChooser:choices({})
    searchChooser:show()
end)
