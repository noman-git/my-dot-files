-- Hyprland configuration.
-- Converted from the JaKooLit hyprlang (.conf) set on 2026-09-02.
-- hyprlang was deprecated in Hyprland 0.55 and is expected to be removed
-- around 0.57. See https://hypr.land/news/26_lua/
--
-- The .conf files it came from are kept in
-- ~/.config/hypr-conf-backup-20260902-115347/ and are no longer read.
-- To go back: rename hyprland.lua out of the way and restart Hyprland.
--
-- Two files stay in hyprlang on purpose:
--   wallust/wallust-hyprland.conf     wallust rewrites it on every wallpaper
--                                     change and hyprlock.conf sources it.
--   UserConfigs/01-UserDefaults.conf  three shell scripts read it as shell.
-- lua/util.lua parses both.

require("lua/env")           -- environment variables
require("lua/settings")      -- input, misc, binds, gestures, layouts
require("lua/decorations")   -- borders, opacity, shadow, blur (wallust colours)
require("lua/animations")    -- active preset, swapped by scripts/Animations.sh
require("lua/keybinds")      -- default keybinds
require("lua/userkeybinds")  -- your own keybinds
require("lua/laptop")        -- laptop keys and touchpad
require("lua/windowrules")   -- window and layer rules
require("lua/startup")       -- autostart

require("monitors")          -- written by nwg-displays
require("workspaces")        -- written by nwg-displays
