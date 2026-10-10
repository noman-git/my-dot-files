# my-dot-files

Config for my Arch laptops: shell, terminal, tmux, neovim, the Hyprland
desktop (JaKooLit dots rewritten in Lua), the system files under `/etc` and
`/boot`, and the package lists. One `git clone --recurse-submodules` plus
`./install_arch.sh` rebuilds a machine, with or without an NVIDIA GPU.
The same shell setup plus a tiling desktop runs on macOS; see
[macOS](#macos).

The repo must live at `~/my-dot-files`. GNU stow links into the parent
directory of the repo, so that path puts everything under `$HOME`.

## Layout

```
git/ zsh/ tmux/ tmux-powerline/ kitty/   stow packages, target is $HOME
nvim/                 stow package; ~/.config/nvim is the my-nvim-config submodule
hypr-desktop/         stow package for the whole desktop:
                        ~/.config/{hypr,waybar,rofi,swaync,wlogout,cava,wallust,btop,
                                   fastfetch,quickshell,Kvantum,qt5ct,qt6ct,gtk-3.0,
                                   nwg-displays,xremap}
                        ~/.config/systemd/user/{hyprland-session.target,xremap.service}
                        ~/.local/bin/hypr-normalize-monitors
system/               files for / that pacman does not own (see install_system.sh)
pkgs/                 package lists by group, one package per line
scripts/              snapshot-packages.sh, bootstrap-desktop-state.sh
seed/wallpaper.jpg    first wallpaper, so wallust has colours before you pick one
install_arch.sh       full setup; calls install_system.sh at the end
install_system.sh     /etc, /boot, SDDM theme, groups, services (sudo, idempotent)
mac-desktop/          stow package for the macOS desktop:
                        ~/.config/{omniwm/settings.toml,hammerspoon/init.lua,
                                   sketchybar,wallust,karabiner}
                        ~/.local/bin/mac-wallpaper
pkgs/Brewfile         macOS packages for brew bundle
install_mac.sh        full macOS setup
install_ubuntu.sh     shell-only setup for Ubuntu machines
lang_setup.sh         pyenv, the neovim virtualenv, node (optional)
setup_shell.sh        chsh to zsh
```

## Fresh machine

1. Install Arch with archinstall: systemd-boot, ext4 root, a user in `wheel`.
   `install_system.sh` edits the boot entry archinstall creates.
2. Log in as the user. Create an SSH key and add it to GitHub
   (`ssh-keygen -t ed25519`, then paste `~/.ssh/id_ed25519.pub` into GitHub).
   `git/.gitconfig` rewrites `https://github.com/` to SSH, so every GitHub
   clone after stow needs the key.
3. `sudo pacman -S git`
4. `git clone --recurse-submodules git@github.com:noman-git/my-dot-files.git ~/my-dot-files`
5. `cd ~/my-dot-files && ./install_arch.sh`
   Flags: `--nvidia` or `--no-nvidia` to override detection, `--dev-services`
   to enable docker, postgresql and valkey, `--skip-aur`, `--no-system`.
   Cursor, GTK and icon themes (Bibata-Modern-Ice, Flat-Remix) come from the
   AUR packages in `pkgs/aur.txt`. On the first laptop the JaKooLit installer
   had extracted them into `~/.icons` and `~/.themes` instead (664 MB, not in
   git); both locations work.
6. Reboot and pick Hyprland in SDDM.
7. Run `nwg-displays`, save, then `hypr-normalize-monitors`. `monitors.lua`
   and `workspaces.lua` are not in git because nwg-displays rewrites them for
   whatever desk the laptop sits at; `monitors.lua.example` and
   `workspaces.lua.example` show the shape. Until you run nwg-displays, every
   connector gets preferred mode at an automatic position from the catch-all
   rule in `hyprland.lua`, and workspaces are not pinned to monitors.
8. Copy wallpapers into `~/Pictures/wallpapers/Dynamic-Wallpapers/{Dark,Light}`
   and pick one with `SUPER+W`. Wallpapers are not in git.
9. `hyprctl devices -j | jq '.mice[].name'` and update the touchpad name in
   `~/.config/hypr/lua/laptop.lua` if it differs.
10. Optional: `./lang_setup.sh` for pyenv, the `neovim` virtualenv and node.

Every step of `install_arch.sh` and `install_system.sh` can be rerun.
`sudo ./install_system.sh --dry-run` prints what would change without root.

## NVIDIA or not

Detection reads the PCI bus for vendor `0x10de` with a display class. With an
NVIDIA GPU the installers add:

- `pkgs/nvidia.txt`: nvidia-open, nvidia-utils, nvidia-prime, nvidia-settings,
  libva-nvidia-driver, nvtop. nvidia-open is the prebuilt module for the
  stock `linux` kernel; another kernel needs nvidia-open-dkms and headers.
- `/etc/modprobe.d/nvidia-pm.conf`: runtime D3 power management.
- `/etc/X11/xorg.conf.d/10-sddm-intel-only.conf`: `AutoAddGPU off`, so the
  SDDM Xorg greeter stays on the primary GPU and does not hold the dGPU awake.
- `nvidia_drm.modeset=1` on the kernel line of the boot entry.
- `/boot/loader/entries/zz-linux-nvidia-disabled.conf`: a rescue entry with the
  NVIDIA modules blacklisted. Boot it when a driver update breaks the desktop.
  It matters because the mkinitcpio preset has no fallback image.

Without an NVIDIA GPU none of that is installed and the kernel line is left
plain. Everything else is the same.

Hybrid laptops (this one: Intel iGPU primary, RTX 4060 through `prime-run`)
keep `LIBVA_DRIVER_NAME` and `__GLX_VENDOR_LIBRARY_NAME` commented out in
`hypr-desktop/.config/hypr/lua/env.lua`. Setting them globally pins every app
to the dGPU. On an NVIDIA-only machine, uncomment them there.

`/etc/mkinitcpio.conf` stays stock with `MODULES=()`. The NVIDIA driver is
not in the initramfs and loads after early boot; `install_system.sh` warns if
`MODULES` is not empty.

Opt-in, not yet tested on this laptop: `sudo ./install_system.sh --sddm-wayland`
installs `/etc/sddm.conf.d/10-wayland.conf`, which runs the SDDM greeter on
Wayland (weston kiosk, SDDM's default Wayland compositor; install `weston`
first). The Xorg greeter holds the dGPU awake and blocks D3cold. If the
greeter does not come up, switch to a TTY and remove the file; the header of
the file has the commands.

## Hyprland

The config is Lua (`hyprland.lua` plus `lua/*.lua`), converted from the
JaKooLit hyprlang set on 2026-09-02 for Hyprland 0.56. `hyprctl keyword` does
not work with a Lua config; use `hyprctl eval`. The module map, the
`hyprctl` translation table, the deliberate behaviour differences and the
verification done are in `hypr-desktop/.config/hypr/NOTES-lua-migration.md`.

Still hyprlang on purpose: `UserConfigs/01-UserDefaults.conf` (three shell
scripts read it), `wallust/wallust-hyprland.conf` (wallust writes it,
hyprlock sources it), `hyprlock.conf`, `hypridle.conf`.

`Hyprland --verify-config -c ~/.config/hypr/hyprland.lua` checks the config
without running it. `hyprctl configerrors` shows live errors.

## State that is not in git

Stow links whole directories, so programs write into the repo working tree.
`.gitignore` covers the generated files:

| Ignored (regenerated at runtime)            | Written by                              |
| ------------------------------------------- | --------------------------------------- |
| `*/wallust/colors-*`, `cava/config`, `quickshell/qml_color.json`, `kitty-themes/01-Wallust.conf`, `hypr/wallust/wallust-hyprland.conf` | wallust, on every wallpaper change |
| `hypr/wallpaper_effects/*`, `rofi/.current_wallpaper` | WallustSwww.sh, WallpaperEffects.sh |
| `waybar/config`, `waybar/style.css` (symlinks) | WaybarLayout.sh, WaybarStyles.sh, DarkLight.sh |
| `hypr/monitors.lua`, `hypr/workspaces.lua` (plus the `.conf` twins), `nwg-displays/profiles/`, `active_profile.json` | nwg-displays, on every save |
| `hypr/.initial_startup_done`                | initial-boot.sh, once                   |
| `gtk-3.0/*` except `gtk.css`, `systemd/user/*.wants/` | nwg-look, systemctl --user enable |

Tracked files that the theme scripts edit in place, committed in the Dark
state: `wallust/wallust.toml`, `swaync/style.css`, `qt5ct/qt5ct.conf`,
`qt6ct/qt6ct.conf`, `wallust/templates/colors-rofi.rasi`, `rofi/config.rasi`
(one `@theme` line, replaced by RofiThemeSelector.sh), `kitty/kitty.conf`.
After a Dark/Light toggle or a theme pick, `git status` shows them modified;
commit or `git checkout` them. The monitor layout is deliberately not one of
these: `hyprland.lua` loads `monitors.lua` and `workspaces.lua` with `pcall`,
so the config is valid with or without them.

Outside the repo: `~/.cache/.theme_mode` (Dark or Light),
`~/.cache/.wallpaper_shuffle_mode` (Dark, Light, All or off),
`~/.cache/.wallpaper_shuffle.pid`, and `~/Pictures/wallpapers/`.

`scripts/bootstrap-desktop-state.sh` creates the minimum of this on a fresh
machine: the seed wallpaper, the two waybar symlinks, the mode files and one
wallust run.

## macOS

Tested on an M4 Pro with macOS 27.0.1 (2026-10-10).

1. Create an SSH key and add it to GitHub, the same as step 2 above.
2. `xcode-select --install` for git.
3. `git clone --recurse-submodules git@github.com:noman-git/my-dot-files.git ~/my-dot-files`
4. `cd ~/my-dot-files && ./install_mac.sh`
   Flags: `--no-brew` skips Homebrew and the Brewfile, `--no-defaults` skips
   the `defaults write` settings (Dock autohide, key repeat, no Spaces
   reordering, no drag-to-edge tiling).
5. Give OmniWM Accessibility and Input Monitoring, and Hammerspoon
   Accessibility, in System Settings > Privacy & Security. Allow the
   Karabiner driver extension and Input Monitoring when Karabiner asks. OmniWM does not
   need Screen Recording; without it, Overview and workspace swipes show no
   window thumbnails.
6. In Raycast, set the hotkey to `Cmd+Space` and turn off the Spotlight
   shortcut in System Settings > Keyboard > Keyboard Shortcuts > Spotlight.
   `Option+D` sends `Cmd+Space`, so it opens whichever launcher has that key.

What replaces what:

| Hyprland desktop          | macOS                                              |
| ------------------------- | -------------------------------------------------- |
| Hyprland (dwindle)        | OmniWM, Dwindle layout by default                  |
| exec binds                | Hammerspoon (`mac-desktop/.config/hammerspoon`)    |
| rofi                      | Raycast                                            |
| cliphist                  | Spotlight clipboard (`Cmd+4`)                      |
| waybar                    | SketchyBar; the macOS menu bar is hidden           |
| wallust + swww            | `mac-wallpaper <image>` (desktoppr, then wallust for the bar) |
| xremap                    | Karabiner: Caps Lock tap is Escape, hold is Hyper  |
| SUPER+SHIFT+Return drop-down | OmniWM Quake terminal (Ghostty)                 |
| grim, slurp, swappy       | `Cmd+Shift+5` toolbar                              |
| hyprlock, hyprsunset      | lock screen, Night Shift                           |
| nwg-displays              | System Settings > Displays, or `displayplacer`     |

mainMod is `Option`, the key in the SUPER position on a Mac keyboard, so the
binds sit where the Hyprland binds sit. `Command` stays free for app
shortcuts. Window binds are in OmniWM; app binds are in Hammerspoon.

| Bind                          | Action                                 |
| ----------------------------- | -------------------------------------- |
| `Option+Return`               | kitty                                  |
| `Option+D`                    | launcher                               |
| `Option+E`                    | Finder                                 |
| `Option+B`                    | default browser                        |
| `Option+Q`                    | close window                           |
| `Option+Space`                | float or tile window                   |
| `Option+Shift+F`              | fullscreen                             |
| `Option+A`                    | Overview                               |
| `Option+Shift+Return`         | drop-down terminal                     |
| `Option+arrows`               | focus                                  |
| `Control+Option+arrows`       | move window                            |
| `Option+Shift+arrows`         | resize                                 |
| `Option+1..9`                 | workspace                              |
| `Option+Shift+1..9`           | move window to workspace               |
| `Option+Tab`, `Option+Shift+Tab` | next, previous workspace            |
| `Option+U`, `Option+Shift+U`  | scratchpad (special workspace)         |
| `Option+G`                    | tab group (scrolling layout only)      |
| `Ctrl+Option+arrows` in Dwindle | move the window; toward a neighbour it joins that tile as a tab, on a tab it takes the tab out |
| `Ctrl+Option+[`, `Ctrl+Option+]` | move the workspace to the monitor on the left, right |
| `Option+Shift+Q`              | quit the active app                    |
| `Option+N`                    | Night Shift on or off (`nightlight`)   |
| `Option+Shift+D`              | dark or light mode                     |
| `Option+Shift+I`              | toggle split                           |
| `Option+Command+L`            | dwindle or scrolling layout            |
| `Option+Shift+S`              | screenshot toolbar                     |
| `Control+Option+L`            | lock screen                            |
| `Control+Option+Space`        | OmniWM command palette                 |
| `Caps Lock` (tap)             | Escape                                 |
| `Option+H`, `Option+Shift+K`  | key hints: search all binds            |
| `Ctrl+Option+P`               | power menu: lock, sleep, log out, restart, shut down |
| `Option+W`                    | wallpaper picker (`~/Pictures/wallpapers`) |
| `Control+Option+W`            | random wallpaper                       |
| `Option+S`                    | web search (Google)                    |
| `Option+Cmd+E`                | emoji (Raycast)                        |
| `Option+Cmd+V`                | clipboard history (Raycast)            |
| `Option+Cmd+C`                | calculator (Raycast root search)       |
| `Control+Option+S`            | window switcher (Raycast)              |
| `Hyper+T/B/C/S/D/M/F`         | kitty, Zen, Chrome, Slack, DBeaver, MongoDB Compass, Finder |

Every other OmniWM bind is listed in `settings.toml` under `[[hotkeys]]`.

The Raycast binds are in Hammerspoon, not in Raycast: Raycast keeps its own
hotkeys in an encrypted database, so they cannot be in git. Hammerspoon opens
the Raycast commands by deeplink. If a link stops working, select the
command in Raycast, press `Cmd+Shift+C` (Copy Deeplink) and put the new link
in `hammerspoon/init.lua`.

The wallpaper picker lists the JPG, PNG and WebP files under
`~/Pictures/wallpapers` (not in git, the same path as on Arch), with
thumbnails cached in `~/.cache/wallpaper-thumbs`. A pick runs
`mac-wallpaper`.

Hyper is `Caps Lock` held (Karabiner sends Ctrl+Option+Shift+Cmd). A Hyper
bind focuses the app, or opens it if it is not running. The list is `apps` in
`hammerspoon/init.lua`.

### Bar and colours

SketchyBar is translucent (`BAR_COLOR` alpha `0x40` plus blur) and shows all
9 OmniWM workspaces with an icon for each app on them and the front app. On
the right: Wi-Fi, Bluetooth (connected devices, through `blueutil`), volume,
a bell, battery and the clock. The bell shows the sum of the Dock badges of
running apps (`lsappinfo`) and opens the Notification Center on click: it
asks Hammerspoon to press `Hyper+N`, the "Show Notification Center" shortcut
that `install_mac.sh` turns on. The status icons of background apps
(NordVPN, Docker and others) stay in the hidden macOS menu bar; move the
pointer to the top edge to show it. On macOS 27 SketchyBar cannot copy them
(Screen Recording and SketchyBar issue #849), and a click on them from the
bar opens their menu off screen. Wi-Fi, Bluetooth, volume and
battery open a menu under the item. The Wi-Fi menu lists the networks
around; Hammerspoon fills it (`hammerspoon://wifi-menu`) because network
names need Location access, which only an app can get. Without it, the menu
lists the saved networks. A saved network joins without a password; a new
one asks for it. The Bluetooth menu connects paired devices and searches for
and pairs new ones. The app icons come from `font-sketchybar-app-font`;
`plugins/icon_map.sh` is the app name to icon map from the same release
(v3.0.5). Download the new `icon_map.sh` from
https://github.com/kvndrsslr/sketchybar-app-font/releases when you update
the font, or new apps show no icon. `sketchybarrc` starts one
`omniwmctl watch` process that sends `omniwm_change` to the bar; this needs
`ipcEnabled = true` in the OmniWM settings. OmniWM's own workspace bar is off,
and `gaps.outer.top = 37` keeps windows 4 points under the 33-point bar.

`mac-wallpaper <image>` sets the wallpaper on every display and runs
`wallust run -d ~/.config/wallust`. wallust on macOS reads
`~/Library/Application Support` by default, hence `-d`. It writes
`~/.config/sketchybar/wallust-colors.sh` (not in git), then reloads
SketchyBar. kitty keeps its own colours: the wallust palette from a dark
wallpaper made typed text and the tmux-powerline segments hard to read
(2026-10-10). `mac-wallpaper` with no image recolours from the last
image. The image path is in `~/.cache/.current_wallpaper`. The OmniWM border
colour is fixed in `settings.toml`; wallust does not change it.

### Editing the OmniWM config

`settings.toml` is the complete file that OmniWM writes. The schema is
strict: one missing key, an unknown hotkey id, or the same id twice makes
OmniWM reject the whole file and run with defaults. Change values in place
and do not delete keys. OmniWM reloads the file on save.

The Settings window writes back to the same file through the symlink, so a
change there shows in `git status`. OmniWM rewrites the file in its own key
order and drops comments, so the file has no comments.

After an OmniWM upgrade that adds a key or a hotkey, OmniWM rewrites the file
and keeps a copy as `settings.toml.pre-v4` (or the next version) next to it.
Commit the rewritten file.

## Daily use

- Edit config where it lives (`~/.config/...`); the files are symlinks into
  this repo. `git status` in `~/my-dot-files` shows what changed.
- neovim: commit and push inside `~/.config/nvim` as before, then
  `git add nvim/.config/nvim && git commit -m "Bump nvim config"` here.
  The installer runs `git submodule update --init --remote`, so a fresh
  machine gets the latest `main` even if this pointer is behind.
- New package installed: `scripts/snapshot-packages.sh` lists what is not
  in `pkgs/`. Add it to the right list, or `--write` to append it to
  `pkgs/unsorted.txt` for sorting later. Exit code 1 means drift.
- After `nwg-displays`: `hypr-normalize-monitors`. It anchors the layout at
  0x0. Far-from-origin coordinates hung Hyprland at startup on this NVIDIA
  laptop (2026-07-04).
- System files changed by hand under `/etc` or `/boot`: copy them into
  `system/` and, if needed, teach `install_system.sh` about them.

## Provenance

- JaKooLit Arch-Hyprland `5acde89` (2025-12-11) installed this machine on
  2025-12-20; JaKooLit Hyprland-Dots `4ca3cc0` (2025-12-18) is the base of
  `hypr-desktop`. Do not run `KooLsDotsUpdate.sh` or the upstream
  `upgrade.sh`: they copy upstream dots over this config. The waybar update
  module points at `Distro_update.sh` for that reason.
- SDDM theme: JaKooLit simple-sddm-2 `fa1ffbd`, cloned pinned by
  `install_system.sh`, with `system/usr/share/sddm/themes/simple_sddm_2/theme.conf`
  on top.
- Scripts patched for the Lua config: `Animations.sh`, `ChangeBlur.sh`,
  `ChangeLayout.sh`, `Dropterminal.sh`, `GameMode.sh`, `KeybindsLayoutInit.sh`,
  `KeyBinds.sh`, `KeyHints.sh`, `Kool_Quick_Settings.sh`,
  `SwitchKeyboardLayout.sh`, `Tak0-Autodispatch.sh`, `Tak0-Per-Window-Switch.sh`,
  `TouchPad.sh`, `UserScripts/RainbowBorders.sh`, `UserScripts/WallpaperRandom.sh`,
  `UserScripts/WallpaperSelect.sh` (images only, the mpvpaper video path is
  removed); `Refresh.sh` and `RefreshNoWaybar.sh` relaunch quickshell with
  `-c overview`; `RofiThemeSelector.sh` replaces the `@theme` line instead of
  appending one per switch (the upstream sed failed on its own delimiter).
- Custom, not upstream: `UserScripts/WallpaperModeShuffle.sh`,
  `WallpaperShuffleStop.sh`, `WallpaperStartup.sh`, `NordVPN.sh`,
  `rofi/config-nordvpn.rasi`, `gtk-3.0/gtk.css` (compact tray menus),
  `systemd/user/hyprland-session.target` (portal fix), `hypr-normalize-monitors`.
- `swww` and `swww-daemon` in `/usr/bin` are symlinks to `awww`; the package
  is `awww`, the JaKooLit scripts call `swww`. `install_system.sh` creates them.

## Known follow-ups

- rofi 2.0 changed the listview default to `flow: horizontal`. Only
  `themes/KooL_style-4.rasi` and `config-nordvpn.rasi` carry the
  `flow: vertical` fix; another theme picked with the selector may need the
  same line in its `listview` block.
- The SDDM Wayland greeter drop-in (`--sddm-wayland`) is prepared but not
  tested here; it needs `weston` and a logout to try.
- `IgnorePkg = tmux` in pacman.conf if the tmux 3.7 dot-fill returns
  (see `configure_pacman` in install_system.sh for where it would go).
- `gsettings get org.gnome.desktop.interface cursor-theme` is `default` on
  this laptop although `HYPRCURSOR_THEME` is Bibata-Modern-Ice; `initial-boot.sh`
  sets it on the first login only.
