-- Window and layer rules.
-- See https://wiki.hypr.land/configuring/core/rules/window-rules/
--
-- The match table holds the props; every other field is an effect.
-- Rules are read top to bottom and the last match wins.
-- "negative:" in front of a pattern inverts it, as it did in hyprlang.

--------------------------------------------------------------------------
-- Tag definitions
--------------------------------------------------------------------------
local tags = {
    { "browser", class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$" },
    { "browser", class = "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$" },
    { "browser", class = "^(chrome-.+-Default)$" },
    { "browser", class = "^([Cc]hromium)$" },
    { "browser", class = "^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable))$" },
    { "browser", class = "^(Brave-browser(-beta|-dev|-unstable)?)$" },
    { "browser", class = "^([Tt]horium-browser|[Cc]achy-browser)$" },
    { "browser", class = "^(zen-alpha|zen)$" },

    { "notif", class = "^(swaync-control-center|swaync-notification-window|swaync-client|class)$" },
    { "KooL_Cheat", title = "^(KooL Quick Cheat Sheet)$" },
    { "KooL_Settings", title = "^(KooL Hyprland Settings)$" },
    { "KooL-Settings", class = "^(nwg-displays|nwg-look)$" },
    { "terminal", class = "^(Alacritty|kitty|kitty-dropterm)$" },
    { "email", class = "^([Tt]hunderbird|org.gnome.Evolution|eu.betterbird.Betterbird)$" },
    { "projects", class = "^(codium|codium-url-handler|VSCodium|VSCode|code|code-url-handler|jetbrains-.+)$" },
    { "screenshare", class = "^(com.obsproject.Studio)$" },
    { "im", class = "^([Dd]iscord|[Ww]ebCord|[Vv]esktop|[Ff]erdium|[Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap|org.telegram.desktop|io.github.tdesktop_x64.TDesktop|teams-for-linux|im.riot.Riot|Element)$" },
    { "games", class = "^(gamescope|steam_app_\\d+)$" },
    { "gamestore", class = "^([Ss]team|com.heroicgameslauncher.hgl)$" },
    { "gamestore", title = "^([Ll]utris)$" },
    { "file-manager", class = "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt|app.drey.Warp)$" },
    { "wallpaper", class = "^([Ww]aytrogen)$" },
    { "multimedia", class = "^([Aa]udacious)$" },
    { "multimedia_video", class = "^([Mm]pv|vlc)$" },

    -- Settings
    { "settings", title = "^(ROG Control|Kvantum Manager)$" },
    { "settings", class = "^(wihotspot(-gui)?|[Bb]aobab|org.gnome.[Bb]aobab|gnome-disks|file-roller|org.gnome.FileRoller|nm-applet|nm-connection-editor|blueman-manager|pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol|qt5ct|qt6ct|[Yy]ad|xdg-desktop-portal-gtk|org.kde.polkit-kde-authentication-agent-1|[Rr]ofi)$" },
    { "viewer", class = "^(gnome-system-monitor|org.gnome.SystemMonitor|io.missioncenter.MissionCenter|evince|eog|org.gnome.Loupe)$" },
}

for _, t in ipairs(tags) do
    local match = {}
    if t.class then
        match.class = t.class
    end
    if t.title then
        match.title = t.title
    end
    hl.window_rule({ match = match, tag = "+" .. t[1] })
end

--------------------------------------------------------------------------
-- General rules, by tag.
-- Tags added by a window rule are dynamic, so they are matched with a "*".
--------------------------------------------------------------------------
hl.window_rule({ match = { tag = "multimedia_video*" }, no_blur = true })
hl.window_rule({ match = { tag = "multimedia_video*" }, opacity = "1.0" })

--------------------------------------------------------------------------
-- Positioning
--------------------------------------------------------------------------
hl.window_rule({ match = { tag = "KooL_Cheat*" }, center = true })
hl.window_rule({ match = { class = "([Tt]hunar)", title = "negative:(.*[Tt]hunar.*)" }, center = true })
hl.window_rule({ match = { title = "^(ROG Control|Keybindings)$" }, center = true })
hl.window_rule({ match = { tag = "KooL-Settings*" }, center = true })
hl.window_rule({
    match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol|[Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap|[Ff]erdium)$" },
    center = true,
})
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, move = { "72%", "7%" } })

--------------------------------------------------------------------------
-- Idle inhibit
--------------------------------------------------------------------------
hl.window_rule({ match = { fullscreen = true }, idle_inhibit = "fullscreen" })

--------------------------------------------------------------------------
-- Float rules
--------------------------------------------------------------------------
hl.window_rule({ match = { tag = "KooL_Cheat*" }, float = true })
hl.window_rule({ match = { tag = "wallpaper*" }, float = true })
hl.window_rule({ match = { tag = "settings*" }, float = true })
hl.window_rule({ match = { tag = "viewer*" }, float = true })
hl.window_rule({ match = { tag = "KooL-Settings*" }, float = true })
hl.window_rule({
    match = { class = "([Zz]oom|onedriver|onedriver-launcher|mpv|com.github.rafostar.Clapper|^[Qq]alculate-gtk|[Ff]erdium)" },
    float = true,
})
hl.window_rule({ match = { class = "org.gnome.Calculator", title = "Calculator" }, float = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, float = true })

--------------------------------------------------------------------------
-- Popups and dialogues
--------------------------------------------------------------------------
hl.window_rule({ match = { title = "^(Authentication Required)$" }, float = true, center = true })
hl.window_rule({
    match = { class = "(codium|VSCodium)", title = "negative:(.*(codium|VSCodium).*)" },
    float = true,
})
hl.window_rule({
    match = { class = "^(com.heroicgameslauncher.hgl)$", title = "negative:(Heroic Games Launcher)" },
    float = true,
})
hl.window_rule({ match = { class = "^([Ss]team)$", title = "negative:^([Ss]team)$" }, float = true })
hl.window_rule({ match = { class = "([Tt]hunar)", title = "negative:(.*[Tt]hunar.*)" }, float = true })

hl.window_rule({
    match = { title = "^(Add Folder to Workspace|Save As)$" },
    float = true,
    center = true,
    size = { "70%", "60%" },
})
hl.window_rule({
    match = { initial_title = "^(Open Files)$" },
    float = true,
    size = { "70%", "60%" },
})
hl.window_rule({
    match = { title = "^(SDDM Background)$" },
    float = true,
    center = true,
    size = { "16%", "12%" },
})

--------------------------------------------------------------------------
-- Opacity
--------------------------------------------------------------------------
hl.window_rule({ match = { tag = "browser*" }, opacity = "0.99 0.8" })
hl.window_rule({ match = { tag = "projects*" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { tag = "im*" }, opacity = "0.94 0.86" })
hl.window_rule({ match = { tag = "multimedia*" }, opacity = "0.94 0.86" })
hl.window_rule({ match = { tag = "file-manager*" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { tag = "terminal*" }, opacity = "0.9 0.7" })
hl.window_rule({ match = { tag = "settings*" }, opacity = "0.8 0.7" })
hl.window_rule({ match = { tag = "viewer*" }, opacity = "0.82 0.75" })
hl.window_rule({ match = { tag = "wallpaper*" }, opacity = "0.9 0.7" })
hl.window_rule({ match = { class = "^(gedit|org.gnome.TextEditor|mousepad)$" }, opacity = "0.8 0.7" })
hl.window_rule({ match = { class = "^(deluge|seahorse)$" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, opacity = "0.95 0.75" })

--------------------------------------------------------------------------
-- Pinning and extras
--------------------------------------------------------------------------
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, pin = true, keep_aspect_ratio = true })
hl.window_rule({ match = { tag = "games*" }, no_blur = true, fullscreen = true })

--------------------------------------------------------------------------
-- Focus
--------------------------------------------------------------------------
hl.window_rule({ match = { class = "^(jetbrains-.*)$" }, no_initial_focus = true })
hl.window_rule({ match = { title = "^(wind.*)$" }, no_initial_focus = true })

--------------------------------------------------------------------------
-- Layer rules
--------------------------------------------------------------------------
hl.layer_rule({ match = { namespace = "rofi" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "notifications" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "quickshell:overview" }, blur = true, ignore_alpha = 0.5 })

--------------------------------------------------------------------------
-- Your own rules (was UserConfigs/WindowRules.conf)
--------------------------------------------------------------------------
-- Sticky (vixalien Notes): float and pin so notes follow across workspaces.
hl.window_rule({
    match = { class = "^(sticky\\.py)$" },
    float = true,
    pin = true,
    opacity = "0.95 0.90",
    no_initial_focus = true,
})
hl.window_rule({
    match = { class = "^(sticky\\.py)$", title = "^(Notes)$" },
    size = { 360, 420 },
})
