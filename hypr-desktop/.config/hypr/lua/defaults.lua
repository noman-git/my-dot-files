-- Default apps and search engine.
-- The values live in UserConfigs/01-UserDefaults.conf, still in hyprlang,
-- because WaybarScripts.sh, RofiSearch.sh and Kool_Quick_Settings.sh read
-- that same file as shell. Edit it there and both sides pick it up.

local util = require("lua/util")

local path = util.userConfigs .. "/01-UserDefaults.conf"
local vars = util.read_vars(path)

util.apply_envs(path)

return {
    term = vars.term or "kitty",
    files = vars.files or "dolphin",
    edit = os.getenv("EDITOR") or "nano",
    searchEngine = vars.Search_Engine or "https://www.google.com/search?q={}",
}
