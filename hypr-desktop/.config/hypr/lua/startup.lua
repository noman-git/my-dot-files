-- Commands and apps run at launch.
-- exec-once is now the "hyprland.start" event.
-- See https://wiki.hypr.land/configuring/core/autostart/

local util = require("lua/util")
local apps = require("lua/defaults")

local scripts = util.scripts
local userScripts = util.userScripts

hl.on("hyprland.start", function()
    -- Applies the initial wallpaper, theming and settings. It checks for
    -- ~/.config/hypr/.initial_startup_done and stops if that file exists,
    -- so leave both the script and that file alone.
    hl.exec_cmd(util.HYPR .. "/initial-boot.sh")

    ----------------------------------------------------------------------
    -- Wallpaper
    -- swww and swww-daemon are symlinks to awww and awww-daemon here.
    -- The .conf started the daemon in both the vendor and the user file;
    -- once is enough.
    ----------------------------------------------------------------------
    hl.exec_cmd("swww-daemon --format xrgb")
    -- WallpaperStartup.sh resumes the last shuffle pool (Dark/Light/All), or
    -- restores the last hand-picked wallpaper if shuffle was off.
    hl.exec_cmd("sleep 1.5 && " .. userScripts .. "/WallpaperStartup.sh")
    -- hl.exec_cmd("mpvpaper '*' -o 'load-scripts=no no-audio --loop' " .. livewallpaper)
    -- Random wallpaper every 30 minutes:
    -- hl.exec_cmd(userScripts .. "/WallpaperAutoChange.sh " .. util.HOME .. "/Pictures/wallpapers")

    ----------------------------------------------------------------------
    -- Session
    ----------------------------------------------------------------------
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    -- Activates graphical-session.target so xdg-desktop-portal (1.22 and
    -- later, gated by Requisite=graphical-session.target) can start. Screen
    -- sharing needs this.
    hl.exec_cmd("systemctl --user start hyprland-session.target")
    hl.exec_cmd(scripts .. "/KeybindsLayoutInit.sh")

    -- Drop-down terminal. See JaKooLit/Hyprland-Dots issue 810.
    hl.exec_cmd(scripts .. "/Dropterminal.sh " .. apps.term)

    -- Polkit (Gnome or KDE)
    hl.exec_cmd(scripts .. "/Polkit.sh")

    ----------------------------------------------------------------------
    -- Tray and bar
    ----------------------------------------------------------------------
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("nm-tray") -- for Ubuntu
    hl.exec_cmd("swaync")
    hl.exec_cmd("waybar")
    hl.exec_cmd("qs -c overview") -- Quickshell overview
    -- hl.exec_cmd("ags")
    -- hl.exec_cmd("blueman-applet")
    -- hl.exec_cmd("rog-control-center")

    ----------------------------------------------------------------------
    -- Clipboard manager
    ----------------------------------------------------------------------
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Rainbow borders
    hl.exec_cmd(userScripts .. "/RainbowBorders.sh")

    -- hypridle, for hyprlock
    hl.exec_cmd("hypridle")

    -- Resumes Hyprsunset if it was on in the previous session.
    hl.exec_cmd(scripts .. "/Hyprsunset.sh init")

    -- Sticky notes daemon at login. Respects the in-app "Start on login" toggle.
    hl.exec_cmd("sticky --autostart")

    ----------------------------------------------------------------------
    -- Available but off by default
    ----------------------------------------------------------------------
    -- Persistent wallpaper:
    -- hl.exec_cmd("swww img " .. util.HOME .. "/Pictures/wallpapers/mecha-nostalgia.png")
    -- Gnome polkit for NixOS:
    -- hl.exec_cmd(scripts .. "/Polkit-NixOS.sh")
    -- xdg-desktop-portal-hyprland should autostart, but can be forced:
    -- hl.exec_cmd(scripts .. "/PortalHyprland.sh")
end)
