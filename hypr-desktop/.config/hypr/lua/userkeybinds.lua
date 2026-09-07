-- Your own keybinds. Check lua/keybinds.lua for conflicts.
-- To replace an existing bind, hl.unbind("KEYS") first, then bind it again.
-- The key string in hl.unbind is case sensitive.

local util = require("lua/util")

local mainMod = "SUPER"

-- NordVPN: searchable server picker, replacing the overflowing tray menu.
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd(util.userScripts .. "/NordVPN.sh"),
    { description = "NordVPN picker" })

-- Sticky notes
hl.bind(mainMod .. " + ALT + N", hl.dsp.exec_cmd("sticky --toggle"),
    { description = "Toggle Sticky notes" })
hl.bind(mainMod .. " + ALT + SHIFT + N", hl.dsp.exec_cmd("sticky --new"),
    { description = "New Sticky note" })

-- Passthrough into a VM.
-- See https://wiki.hypr.land/configuring/core/binds/submaps/
-- hl.define_submap("passthru", function()
--     hl.bind(mainMod .. " + ALT + P", hl.dsp.submap("reset"))
-- end)
-- hl.bind(mainMod .. " + ALT + P", hl.dsp.submap("passthru"))
