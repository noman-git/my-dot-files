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
-- shows an alert on every press, so no message is passed. Every bind is also
-- recorded for the key hints (Option+H).
local hammerspoonBinds = {}
local function bind(mods, key, desc, fn)
    hs.hotkey.bind(mods, key, nil, fn)
    table.insert(hammerspoonBinds, { mods = mods, key = key, desc = desc, fn = fn })
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

local setShuffle
local wallpaperChooser = hs.chooser.new(function(choice)
    if not choice then return end
    if choice.shuffle ~= nil then
        setShuffle(choice.shuffle)
        hs.alert.show("Wallpaper shuffle " .. (choice.shuffle and "on (every 30 minutes)" or "off"))
    else
        setWallpaper(choice.path)
    end
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
    local shuffling = hs.settings.get("wallpaperShuffle") == true
    local choices = { {
        text = shuffling and "Stop wallpaper shuffle" or "Shuffle wallpapers every 30 minutes",
        subText = shuffling and "Shuffle is on" or "Shuffle is off",
        shuffle = not shuffling,
    } }
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

-- Wallpaper effects, like WallpaperEffects.sh (Option+Shift+W): ImageMagick
-- applies an effect to the last wallpaper that mac-wallpaper set (path in
-- ~/.cache/.current_wallpaper) and sets the result. "No Effects" sets the
-- original again. The effect image is ~/.cache/wallpaper-effects/current.jpg.
local MAGICK = "/opt/homebrew/bin/magick"
local EFFECT_DIR = os.getenv("HOME") .. "/.cache/wallpaper-effects"
local ORIGINAL_STATE = os.getenv("HOME") .. "/.cache/.wallpaper_original"
local WALLPAPER_EFFECTS = {
    { "No Effects", nil },
    { "Black & White", { "-colorspace", "gray", "-sigmoidal-contrast", "10,40%" } },
    { "Blurred", { "-blur", "0x10" } },
    { "Charcoal", { "-charcoal", "0x5" } },
    { "Edge Detect", { "-edge", "1" } },
    { "Emboss", { "-emboss", "0x5" } },
    { "Frame Raised", { "+raise", "150" } },
    { "Frame Sunk", { "-raise", "150" } },
    { "Negate", { "-negate" } },
    { "Oil Paint", { "-paint", "4" } },
    { "Posterize", { "-posterize", "4" } },
    { "Polaroid", { "-polaroid", "0" } },
    { "Sepia Tone", { "-sepia-tone", "65%" } },
    { "Solarize", { "-solarize", "80%" } },
    { "Sharpen", { "-sharpen", "0x5" } },
    { "Vignette", { "-vignette", "0x3" } },
    { "Vignette-black", { "-background", "black", "-vignette", "0x3" } },
    { "Zoomed", { "-gravity", "Center", "-extent", "1:1" } },
}

local function readFile(path)
    local f = io.open(path)
    if not f then return nil end
    local s = f:read("*l")
    f:close()
    return s
end

local function writeFile(path, s)
    local f = io.open(path, "w")
    if f then f:write(s, "\n"); f:close() end
end

-- The original of the current wallpaper: the effect output is never used as
-- the input of the next effect.
local function originalWallpaper()
    local current = readFile(os.getenv("HOME") .. "/.cache/.current_wallpaper")
    if current and not current:find(EFFECT_DIR, 1, true) then
        writeFile(ORIGINAL_STATE, current)
        return current
    end
    return readFile(ORIGINAL_STATE)
end

local effectChooser = hs.chooser.new(function(choice)
    if not choice then return end
    local original = originalWallpaper()
    if not original then
        hs.alert.show("Set a wallpaper first (Option+W)")
        return
    end
    local effect = WALLPAPER_EFFECTS[choice.index][2]
    if not effect then
        setWallpaper(original)
        return
    end
    hs.fs.mkdir(EFFECT_DIR)
    -- A new file name each time: macOS does not reload a wallpaper whose path
    -- did not change.
    local out = string.format("%s/%s.jpg", EFFECT_DIR, os.time())
    hs.execute("rm -f '" .. EFFECT_DIR .. "'/*.jpg")
    local args = { original }
    for _, a in ipairs(effect) do table.insert(args, a) end
    table.insert(args, out)
    hs.alert.show("Applying " .. choice.text .. "…")
    hs.task.new(MAGICK, function(code, _, err)
        if code == 0 then setWallpaper(out) else hs.alert.show("magick failed: " .. (err or "")) end
    end, args):start()
end)
effectChooser:placeholderText("Wallpaper effect")
local effectChoices = {}
for i, e in ipairs(WALLPAPER_EFFECTS) do table.insert(effectChoices, { text = e[1], index = i }) end
effectChooser:choices(effectChoices)
bind({ "alt", "shift" }, "w", "wallpaper effects", function() effectChooser:show() end)

-- Wallpaper shuffle, like WallpaperAutoChange.sh: a random wallpaper every
-- 30 minutes. Switch it on and off from the wallpaper picker (Option+W); the
-- state survives a Hammerspoon restart (hs.settings).
local SHUFFLE_SECONDS = 1800
local shuffleTimer
function setShuffle(on)
    if shuffleTimer then shuffleTimer:stop(); shuffleTimer = nil end
    hs.settings.set("wallpaperShuffle", on)
    if on then
        shuffleTimer = hs.timer.doEvery(SHUFFLE_SECONDS, function()
            local files = wallpapers()
            if #files > 0 then setWallpaper(files[math.random(#files)]) end
        end)
    end
end
setShuffle(hs.settings.get("wallpaperShuffle") == true)

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

-- Quit the active app, like KillActiveProcess.sh (a normal quit signal, not
-- a force kill).
bind({ "alt", "shift" }, "q", "quit the active app", function()
    local app = hs.application.frontmostApplication()
    if app then app:kill() end
end)

-- Night Shift on or off, like Hyprsunset.sh. Uses the nightlight CLI.
bind(mainMod, "n", "night shift on or off", function()
    local out = hs.execute("/opt/homebrew/bin/nightlight toggle && /opt/homebrew/bin/nightlight status")
    hs.alert.show("Night Shift " .. (out or ""):gsub("%s+$", ""))
end)

-- Dark or light mode, like DarkLight.sh. Asks once for Automation access
-- to System Events.
bind({ "alt", "shift" }, "d", "dark or light mode", function()
    hs.osascript.applescript('tell application "System Events" to tell appearance preferences '
        .. 'to set dark mode to not dark mode')
end)

-- Power menu, like wlogout on Arch (Ctrl+Option+P). Log out, restart and
-- shut down ask first.
local function confirmed(action)
    return hs.dialog.blockAlert(action .. "?", "", action, "Cancel") == action
end
local powerActions = {
    { text = "Lock", subText = "Lock the screen", run = hs.caffeinate.lockScreen },
    { text = "Sleep", subText = "Put the Mac to sleep", run = hs.caffeinate.systemSleep },
    { text = "Log Out", subText = "Close all apps and log out",
        run = function() if confirmed("Log Out") then hs.caffeinate.logOut() end end },
    { text = "Restart", subText = "Restart the Mac",
        run = function() if confirmed("Restart") then hs.caffeinate.restartSystem() end end },
    { text = "Shut Down", subText = "Turn the Mac off",
        run = function() if confirmed("Shut Down") then hs.caffeinate.shutdownSystem() end end },
}
local powerChooser = hs.chooser.new(function(choice)
    if choice then powerActions[choice.index].run() end
end)
powerChooser:placeholderText("Power")
local powerChoices = {}
for i, a in ipairs(powerActions) do
    table.insert(powerChoices, { text = a.text, subText = a.subText, index = i })
end
powerChooser:choices(powerChoices)
bind({ "ctrl", "alt" }, "p", "power menu", function() powerChooser:show() end)

-- Key hints, like KeyHints.sh and KeyBinds.sh on Arch (Option+H and
-- Option+Shift+K): a searchable list of the Hammerspoon binds above, the
-- OmniWM binds read from its settings.toml, and the Karabiner and macOS keys.
-- Enter on a Hammerspoon bind runs it.
local MOD_NAMES = { ctrl = "Ctrl", alt = "Option", shift = "Shift", cmd = "Cmd" }
local function chord(mods, key)
    local set = {}
    for _, m in ipairs(mods) do set[m] = true end
    local parts = {}
    if set.ctrl and set.alt and set.shift and set.cmd then
        parts = { "Hyper" }
    else
        for _, m in ipairs({ "ctrl", "alt", "shift", "cmd" }) do
            if set[m] then table.insert(parts, MOD_NAMES[m]) end
        end
    end
    local k = key == "return" and "Return" or key == "space" and "Space" or key:upper()
    table.insert(parts, k)
    return table.concat(parts, "+")
end

-- "moveToWorkspace.0" -> "move to workspace 1", "focus.left" -> "focus left"
local function omniwmLabel(id)
    local name, arg = id:match("^([^.]+)%.?(.*)$")
    local words = name:gsub("(%u)", " %1"):lower()
    if arg:match("^%d+$") and (name == "switchWorkspace" or name == "moveToWorkspace"
        or name == "focusColumn" or name == "moveColumnToWorkspace") then
        arg = tostring(tonumber(arg) + 1)
    end
    arg = arg:gsub("(%d+)", " %1 "):gsub("(%u)", " %1"):lower()
    return (words .. " " .. arg):gsub("%.", " "):gsub("%s+", " "):gsub("%s$", "")
end

local function omniwmBinds()
    local f = io.open(os.getenv("HOME") .. "/.config/omniwm/settings.toml")
    if not f then return {} end
    local text = f:read("*a")
    f:close()
    local out = {}
    for binding, id in text:gmatch('%[%[hotkeys%]%]%s*binding = "([^"]+)"%s*id = "([^"]+)"') do
        if binding ~= "Unassigned" then
            table.insert(out, { text = binding:gsub("Control", "Ctrl"):gsub("Command", "Cmd"),
                subText = "OmniWM: " .. omniwmLabel(id) })
        end
    end
    return out
end

local EXTRA_HINTS = {
    { text = "Caps Lock (tap)", subText = "Karabiner: Escape" },
    { text = "Caps Lock (hold)", subText = "Karabiner: Hyper (Ctrl+Option+Shift+Cmd)" },
    { text = "Hyper+N", subText = "macOS: show the Notification Center" },
    { text = "Cmd+Shift+3 / 4 / 5", subText = "macOS: screenshot of the screen / an area / toolbar with recording" },
    { text = "Cmd+Ctrl+Shift+4", subText = "macOS: screenshot of an area to the clipboard" },
    { text = "Cmd+4 (in Spotlight)", subText = "macOS: clipboard history" },
}

local hintsChooser = hs.chooser.new(function(choice)
    if choice and choice.index then hammerspoonBinds[choice.index].fn() end
end)
hintsChooser:placeholderText("Search keybinds")
hintsChooser:rows(14)
hintsChooser:searchSubText(true)
local function showHints()
    local choices = {}
    for i, b in ipairs(hammerspoonBinds) do
        table.insert(choices, { text = chord(b.mods, b.key), subText = "Hammerspoon: " .. b.desc, index = i })
    end
    for _, c in ipairs(omniwmBinds()) do table.insert(choices, c) end
    for _, c in ipairs(EXTRA_HINTS) do table.insert(choices, c) end
    hintsChooser:choices(choices)
    hintsChooser:query("")
    hintsChooser:show()
end
bind(mainMod, "h", "key hints", showHints)
bind({ "alt", "shift" }, "k", "search keybinds", showHints)

-- Music, like RofiBeats.sh (Option+Shift+M): the online stations and YouTube
-- links from the Arch list (hypr-desktop/.config/rofi/online_music.list,
-- read from the repo so both machines share one list) and the files in
-- ~/Music, played with mpv (yt-dlp for YouTube). One player at a time.
local MPV = "/opt/homebrew/bin/mpv"
local MUSIC_LIST = os.getenv("HOME") .. "/my-dot-files/hypr-desktop/.config/rofi/online_music.list"
local MUSIC_DIR = os.getenv("HOME") .. "/Music"
local musicTask, musicTitle

local function stopMusic()
    if musicTask and musicTask:isRunning() then musicTask:terminate() end
    musicTask, musicTitle = nil, nil
end

local function playMusic(title, args)
    stopMusic()
    local full = { "--no-video", "--really-quiet" }
    for _, a in ipairs(args) do table.insert(full, a) end
    musicTask = hs.task.new(MPV, function(code)
        if code ~= 0 and musicTitle == title then hs.alert.show("Could not play " .. title) end
    end, full)
    -- yt-dlp lives in Homebrew, which is not on the PATH of Hammerspoon tasks.
    musicTask:setEnvironment({ PATH = "/opt/homebrew/bin:/usr/bin:/bin", HOME = os.getenv("HOME") })
    musicTask:start()
    musicTitle = title
    hs.alert.show("Now playing: " .. title)
end

local musicChooser = hs.chooser.new(function(choice)
    if not choice then return end
    if choice.stop then
        stopMusic()
        hs.alert.show("Music stopped")
    elseif choice.shuffleLocal then
        playMusic("Shuffle ~/Music", { "--shuffle", "--loop-playlist", MUSIC_DIR })
    else
        playMusic(choice.text, choice.url and { "--shuffle", choice.url } or { choice.path })
    end
end)
musicChooser:placeholderText("Music")
musicChooser:searchSubText(true)

bind({ "alt", "shift" }, "m", "music", function()
    local choices = {}
    if musicTitle then
        table.insert(choices, { text = "Stop music", subText = "Playing: " .. musicTitle, stop = true })
    end
    local f = io.open(MUSIC_LIST)
    if f then
        for line in f:lines() do
            local name, url = line:match("^(.-)|(.+)$")
            if name then table.insert(choices, { text = name, subText = "Online", url = url }) end
        end
        f:close()
    end
    local out = hs.execute("find -L '" .. MUSIC_DIR .. "' -type f \\( -iname '*.mp3' -o -iname '*.flac'"
        .. " -o -iname '*.wav' -o -iname '*.ogg' -o -iname '*.m4a' \\) 2>/dev/null | sort") or ""
    local localCount = 0
    for path in out:gmatch("[^\n]+") do
        localCount = localCount + 1
        table.insert(choices, { text = path:match("([^/]+)$"), subText = "~/Music", path = path })
    end
    if localCount > 0 then
        table.insert(choices, 1 + (musicTitle and 1 or 0),
            { text = "Shuffle all local music", subText = localCount .. " files in ~/Music", shuffleLocal = true })
    end
    musicChooser:choices(choices)
    musicChooser:query("")
    musicChooser:show()
end)

-- Sticky notes, like sticky on Arch: Option+Cmd+N shows or hides Stickies,
-- Option+Cmd+Shift+N makes a new note. OmniWM floats Stickies (app rule).
local STICKIES = "com.apple.Stickies"
bind({ "alt", "cmd" }, "n", "show or hide sticky notes", whenModifiersUp(function()
    local app = hs.application.get(STICKIES)
    if app and app:isFrontmost() then app:hide() else hs.application.launchOrFocusByBundleID(STICKIES) end
end))
bind({ "alt", "cmd", "shift" }, "n", "new sticky note", whenModifiersUp(function()
    hs.application.launchOrFocusByBundleID(STICKIES)
    hs.timer.waitUntil(function()
        local app = hs.application.get(STICKIES)
        return app and app:isFrontmost()
    end, function() hs.eventtap.keyStroke({ "cmd" }, "n", 0) end, 0.05)
end))

-- Location for the bar's weather item: write "lat,lon" to ~/.cache/location
-- at start and every hour. With a VPN the IP address shows the VPN server's
-- city, so the weather item prefers this file.
local LOCATION_FILE = os.getenv("HOME") .. "/.cache/location"
local function saveLocation()
    hs.location.start()
    hs.timer.doAfter(10, function()
        local loc = hs.location.get()
        hs.location.stop()
        if loc and loc.latitude then
            writeFile(LOCATION_FILE, string.format("%.3f,%.3f", loc.latitude, loc.longitude))
        end
    end)
end
saveLocation()
local locationTimer = hs.timer.doEvery(3600, saveLocation)
