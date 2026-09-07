-- Shared helpers for the Hyprland Lua config.

local M = {}

M.HOME = os.getenv("HOME") or ""
M.HYPR = M.HOME .. "/.config/hypr"
M.scripts = M.HYPR .. "/scripts"
M.userScripts = M.HYPR .. "/UserScripts"
M.userConfigs = M.HYPR .. "/UserConfigs"

-- Reads the "$name = value" pairs out of a hyprlang file.
-- Two files stay in hyprlang on purpose:
--   wallust/wallust-hyprland.conf   wallust rewrites it on every wallpaper
--                                   change, and hyprlock.conf sources it.
--   UserConfigs/01-UserDefaults.conf  WaybarScripts.sh, RofiSearch.sh and
--                                   Kool_Quick_Settings.sh read it as shell.
function M.read_vars(path)
    local vars = {}
    local fh = io.open(path, "r")
    if not fh then
        return vars
    end
    for line in fh:lines() do
        local name, value = line:match("^%s*%$([%w_]+)%s*=%s*(.-)%s*$")
        if name then
            value = value:gsub("%s+#.*$", "")
            value = value:gsub('^"(.*)"$', "%1")
            value = value:gsub("^'(.*)'$", "%1")
            vars[name] = value
        end
    end
    fh:close()
    return vars
end

-- Applies the "env = KEY,VALUE" lines of a hyprlang file.
function M.apply_envs(path)
    local fh = io.open(path, "r")
    if not fh then
        return
    end
    for line in fh:lines() do
        local key, value = line:match("^%s*env%s*=%s*([%w_]+)%s*,%s*(.-)%s*$")
        if key then
            value = value:gsub("%s+#.*$", "")
            hl.env(key, value)
        end
    end
    fh:close()
end

-- Multiplies cursor.zoom_factor, with 1.0 as the floor.
-- Replaces the old "hyprctl keyword cursor:zoom_factor $(... awk ...)" pipeline.
function M.zoom(multiplier)
    return function()
        local factor = tonumber(hl.get_config("cursor.zoom_factor")) or 1
        if factor < 1 then
            factor = 1
        end
        hl.config({ cursor = { zoom_factor = factor * multiplier } })
    end
end

return M
