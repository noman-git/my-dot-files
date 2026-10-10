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
claude/               ~/.claude/settings.json (hooks) and ~/.local/bin/claude-notify
btop/ fastfetch/      stow packages, shared by Arch and macOS
nvim/                 stow package; ~/.config/nvim is the my-nvim-config submodule
hypr-desktop/         stow package for the whole desktop:
                        ~/.config/{hypr,waybar,rofi,swaync,wlogout,cava,wallust,
                                   quickshell,Kvantum,qt5ct,qt6ct,gtk-3.0,
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
                        ~/Library/LaunchAgents/com.noman.{glassbar,login-apps}.plist
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
   reordering, no drag-to-edge tiling, hidden menu bar, the Notification
   Center shortcut).
5. Permissions, in System Settings > Privacy & Security:
   - OmniWM: Accessibility, Input Monitoring and Screen Recording. Screen
     Recording is optional, but without it OmniWM shows its permission
     window at every login and Overview has no window thumbnails.
   - Hammerspoon: Accessibility and Location Services (Wi-Fi network names,
     weather place). Deny its Screen Recording request; nothing here needs it.
   - Karabiner: allow the driver extension and Input Monitoring when it asks.
6. System Settings > General > Login Items: add OmniWM and Hammerspoon under
   Open at Login. SketchyBar starts as a `brew services` agent and Karabiner
   adds its own login items.
7. In Raycast, set the hotkey to `Cmd+Space` and turn off the Spotlight
   shortcut in System Settings > Keyboard > Keyboard Shortcuts > Spotlight.
   `Option+D` sends `Cmd+Space`, so it opens whichever launcher has that key.
8. Lock when the display sleeps, the same 10 minutes as hypridle on Arch:
   `sysadminctl -screenLock immediate -password -` and
   `sudo pmset -b displaysleep 10` (on power it is 10 already).
9. System Settings > Accessibility > Zoom: turn on "Use scroll gesture with
   modifier keys to zoom". macOS protects this setting from scripts.
10. Log out and in once, so every app picks up the hidden menu bar.

What replaces what:

| Arch                      | macOS                                              |
| ------------------------- | -------------------------------------------------- |
| Hyprland (dwindle)        | OmniWM, Dwindle layout by default                  |
| exec binds                | Hammerspoon (`mac-desktop/.config/hammerspoon`)    |
| rofi                      | Raycast, plus Hammerspoon choosers for wallpapers, effects, music, search, key hints and the power menu |
| cliphist                  | Spotlight clipboard (`Cmd+4`) or Raycast           |
| waybar                    | SketchyBar; the macOS menu bar is hidden           |
| swaync                    | the bell in SketchyBar and the Notification Center |
| wallust + swww            | `mac-wallpaper <image>` (desktoppr, then wallust for the bar) |
| xremap                    | Karabiner: Caps Lock tap is Escape, hold is Hyper  |
| drop-down terminal        | kitty quick access terminal (`kitty/.config/kitty/quick-access-terminal.conf`) |
| grim, slurp, swappy       | `Cmd+Shift+5` toolbar                              |
| hyprlock, hypridle        | macOS lock screen and display sleep (step 8)       |
| hyprsunset                | Night Shift through `nightlight`                   |
| wlogout                   | power menu (`Ctrl+Option+P`)                       |
| RofiBeats                 | music menu (`Option+Shift+M`), mpv and yt-dlp      |
| sticky                    | Stickies                                           |
| cava                      | cava with Core Audio tap input, colours from wallust |
| zoom (`SUPER+ALT+scroll`) | macOS Zoom: scroll with a modifier key (step 10)   |
| nwg-displays              | System Settings > Displays; macOS saves the layout for each set of connected displays |

mainMod is `Option`, the key in the SUPER position on a Mac keyboard, so the
binds sit where the Hyprland binds sit. `ALT` binds on Arch use `Command`
here. Window binds are in OmniWM; app binds are in Hammerspoon. `Option+H`
lists every bind, including all OmniWM binds read from its `settings.toml`.

| Bind                          | Action                                 |
| ----------------------------- | -------------------------------------- |
| `Option+Return`               | kitty                                  |
| `Option+D`                    | launcher                               |
| `Option+E`                    | Finder                                 |
| `Option+B`                    | default browser                        |
| `Option+Q`                    | close window                           |
| `Option+Shift+Q`              | quit the active app                    |
| `Option+Space`                | float or tile window                   |
| `Option+Shift+F`              | fullscreen                             |
| `Option+A`                    | Overview                               |
| `Option+Shift+Return`         | drop-down terminal (kitty), show or hide |
| ``Option+` ``, ``Option+Shift+` `` | next, previous window on this workspace (Arch `ALT+Tab`) |
| `Option+arrows`               | focus                                  |
| `Ctrl+Option+arrows`          | move window; in Dwindle, toward a neighbour it joins that tile as a tab, on a tab it takes the tab out |
| `Option+Shift+arrows`         | resize                                 |
| `Option+1..9`                 | workspace                              |
| `Option+Shift+1..9`           | move window to workspace and follow it |
| `Option+Tab`, `Option+Shift+Tab` | next, previous workspace            |
| `Option+U`, `Option+Shift+U`  | scratchpad (special workspace)         |
| `Option+G`                    | tab group (scrolling layout only)      |
| `Option+Shift+I`              | toggle split                           |
| `Option+Cmd+L`                | Dwindle or scrolling layout            |
| `Ctrl+Option+[`, `Ctrl+Option+]` | move the workspace to the monitor on the left, right |
| `Ctrl+Option+Space`           | OmniWM command palette                 |
| `Option+H`, `Option+Shift+K`  | key hints: search all binds            |
| `Ctrl+Option+P`               | power menu: lock, sleep, log out, restart, shut down |
| `Ctrl+Option+L`               | lock screen                            |
| `Option+N`                    | Night Shift on or off                  |
| `Option+Shift+D`              | dark or light mode                     |
| `Option+Shift+S`              | screenshot toolbar                     |
| `Option+W`                    | wallpaper picker; its first row switches the 30-minute shuffle |
| `Option+Shift+W`              | wallpaper effects                      |
| `Ctrl+Option+W`               | random wallpaper                       |
| `Option+Shift+M`              | music: online stations and ~/Music     |
| `Ctrl+Option+Cmd+B`           | show or hide the bar (and its glass)   |
| `Option+Cmd+R`                | reload the bar, glassbar and Hammerspoon |
| `Option+Cmd+U`                | `brew update && brew upgrade` in a new kitty window |
| `Option+S`                    | web search (Google)                    |
| `Option+Cmd+E`                | emoji (Raycast)                        |
| `Option+Cmd+V`                | clipboard history (Raycast)            |
| `Option+Cmd+C`                | calculator (Raycast root search)       |
| `Ctrl+Option+S`               | window switcher (Raycast)              |
| `Option+Cmd+N`, `Option+Cmd+Shift+N` | show or hide sticky notes, new note |
| `Caps Lock` (tap)             | Escape                                 |
| `Hyper+N`                     | Notification Center                    |
| `Hyper+T/B/C/S/D/M/F`         | kitty, Zen, Chrome, Slack, DBeaver, MongoDB Compass, Finder |

OmniWM follows macOS app activation and has no setting for it (0.7.6). So
`Option+Return` and `Option+E` noted a new window, but macOS first showed
the app's older window and OmniWM jumped to that workspace. Hammerspoon
follows `omniwmctl subscribe` and undoes such jumps: a window opened by
those binds stays on the workspace you pressed them on, and when the last
window of a workspace closes, a jump within 1.5 seconds is switched back.
Any key press with `Option` cancels that guard. `Option+E` always makes a
new Finder window through AppleScript (`open ~` only brought up an existing
one), so Hammerspoon asks once for Automation access to Finder.

Hyper is `Caps Lock` held (Karabiner sends Ctrl+Option+Shift+Cmd). A Hyper
bind focuses the app, or opens it if it is not running. The list is `apps` in
`hammerspoon/init.lua`. Hammerspoon opens apps only after every modifier is
up, because Zen, like Firefox, opens Troubleshoot Mode when Option or Shift
is down at launch.

The Raycast binds are in Hammerspoon, not in Raycast: Raycast keeps its own
hotkeys in an encrypted database, so they cannot be in git. Hammerspoon opens
the Raycast commands by deeplink. If a link stops working, select the
command in Raycast, press `Cmd+Shift+C` (Copy Deeplink) and put the new link
in `hammerspoon/init.lua`.

### Bar

SketchyBar has no background. Its items sit in glass capsules like the
macOS Control Center tiles: music, workspaces 1 to 5, workspaces 6 to 9,
status (Wi-Fi to VPN) and time (weather and clock). SketchyBar itself can
only draw a flat tint, an edge and a blur, so `glassbar`
(`helpers/glassbar/main.swift`, built by `install_mac.sh` into
`~/.local/bin`) draws Apple's real Liquid Glass (`NSGlassEffectView`, macOS
26 and later) in borderless windows at level -21, just below SketchyBar's
windows (-20). The style is clear glass, a 20% dark tint and
`effectIsInteractive` (demo variant 6). Liquid Glass draws its highlights
only while its window looks active, and glassbar is never the active app,
so its windows (`ActiveLookPanel`) always report the active look; they
still refuse keyboard focus. Each capsule is a transparent SketchyBar bracket; glassbar
reads its place with `sketchybar --query` once a second, and at once when
`plugins/workspaces.sh` or a bar reload sends it SIGUSR1. launchd runs it
(`mac-desktop/Library/LaunchAgents/com.noman.glassbar.plist`, stowed into
`~/Library/LaunchAgents`, errors in `/tmp/glassbar.err`) and restarts it if
it stops; starting it from `sketchybarrc` failed now and then on a reload.
Open menus get glass too: SketchyBar draws a menu as windows at level 101
and reports no places for them, so glassbar reads them from the macOS
window list every 0.1 seconds and puts one glass panel (corner radius 20,
30% tint) at level 100 behind them; SketchyBar's own menu background is
transparent. OmniWM does not manage its windows. `glassbar --demo` opens a window with
six glass variants over coloured stripes, to compare styles. An empty
`spacer.time` item keeps the two right capsules apart, because a capsule
covers its items' padding. The active workspace is a white pill with dark
text, like an active Control Center toggle. The colours in `colors.sh` are
fixed, so the bar looks the same on every wallpaper. The 9
OmniWM workspaces, each with an icon for every app on it, sit around the
camera notch: 1 to 5 left of it (position `q`), 6 to 9 right of it (`e`). A
workspace shows at most 2 app icons, then `+N`, so 6 to 9 do not grow into
the system items on the right; the clock shows only the time, the volume
only its icon, and the VPN icon only while a VPN is on. On
a display without a notch they sit around the middle. The music bars are
at the far left. `sketchybarrc` starts `plugins/omniwm_watch.sh`, which runs
`omniwmctl watch` in a loop and sends `omniwm_change` to the bar; this needs
`ipcEnabled = true` in the OmniWM settings. OmniWM's own workspace bar is
off. `gaps.outer.top = 38` keeps windows 6 points under the bar, and
`gaps.fullscreenUsesOuterGaps = true` does the same for a single window
and for `Option+Shift+F`; without it a lone window went under the bar. The app icons come from `font-sketchybar-app-font`;
`plugins/icon_map.sh` is the app name to icon map from the same release
(v3.0.5). Download the new `icon_map.sh` from
https://github.com/kvndrsslr/sketchybar-app-font/releases when you update
the font, or new apps show no icon.

On the right, from the right edge: clock, weather, VPN, bell, battery,
volume, Bluetooth, Wi-Fi.

- The music bars are cava, like `WaybarCava.sh` on Arch: Hammerspoon runs
  `plugins/cava_bar.sh`, which reads 12 bars from cava (`cava_bar.conf`,
  Core Audio tap) and writes them as block characters into the item.
  Hammerspoon starts it so that the audio permission belongs to a fixed app:
  add `/Applications/Hammerspoon.app` under **System Audio Recording Only**,
  then reload Hammerspoon. Without the permission cava stops at once and
  opens System Settings, so Hammerspoon does not restart it and shows a
  message. cava runs only while sound plays: macOS shows its purple privacy
  dot at the top right for as long as anything records system audio.
  Hammerspoon reads `pmset -g assertions` every 2 seconds; an output device
  of coreaudiod holds a note while it plays. It starts cava then and stops
  it after 5 seconds without one. The bar keeps 26 points of right padding
  for the dot.

- Wi-Fi, Bluetooth, volume and battery open a menu under the item. Menu
  entries are fixed slots that `sketchybarrc` makes and the scripts fill;
  removing and adding popup items while a menu was open left an empty menu
  that did not close.
- Wi-Fi lists the networks around. Hammerspoon fills the menu
  (`hammerspoon://wifi-menu`), because network names need Location access,
  which only an app can get. Without it, the menu lists the saved networks.
  A saved network joins without a password; a new one asks for it.
- Bluetooth connects paired devices, and searches for and pairs new ones
  (`blueutil`). Volume has a slider, mute and the outputs (`switchaudio-osx`).
- The bell shows the sum of the Dock badges of running apps (`lsappinfo`).
  A click asks Hammerspoon to press `Hyper+N`, the "Show Notification
  Center" shortcut that `install_mac.sh` turns on.
- The VPN icon is on when the default route goes through a `utun`
  interface. NordVPN for macOS has no command-line tool, so a click opens
  the app.
- The weather comes from wttr.in for the place in `~/.cache/location`,
  which Hammerspoon writes every hour from Location Services. The IP
  address would give the VPN server's city. A click shows 3 days.

The status icons of background apps (NordVPN, Docker and others) stay in the
hidden macOS menu bar; move the pointer to the top edge to show it. On
macOS 27 SketchyBar cannot copy them (Screen Recording and SketchyBar issue
#849), and pressing them through Accessibility opens their menu off screen.

### Wallpaper and colours

`mac-wallpaper <image>` sets the wallpaper on every display and runs
`wallust run -s -d ~/.config/wallust`. wallust on macOS reads
`~/Library/Application Support` by default, hence `-d`. It writes only the
cava config; the bar keeps its fixed glass colours, because wallust accents
from dark wallpapers were too dark on the glass. `mac-wallpaper` with no
image recolours from the last image; the path is in
`~/.cache/.current_wallpaper`.

kitty keeps its own colours. `-s` stops wallust from sending colour codes to
open terminals: without it every wallpaper change turned kitty's green and
background into dark wallpaper colours, and tmux saved them for each pane.
To clean panes that got them, send `\033]104\007\033]110\007\033]111\007`
to each `#{pane_tty}`, or open new panes.

wallust also writes `~/.config/cava/config` from
`templates/colors-cava`: the Arch gradient, with `method = coreaudio` and
`source = tap`, which reads the system output without a loopback device
(macOS 14.2 and later). kitty 0.49 does not declare
`NSAudioCaptureUsageDescription`, so macOS never shows a dialog for it: add
`/Applications/kitty.app` by hand under System Settings > Privacy & Security
> Screen & System Audio Recording > **System Audio Recording Only** (the
lower list; the upper one is full screen recording and does not count).
For cava in the drop-down, add
`/Applications/kitty.app/Contents/kitty-quick-access.app` too. Inside tmux
the check goes to the tmux server, so run cava in a kitty window without
tmux.

The picker (`Option+W`) lists the JPG, PNG and WebP files under
`~/Pictures/wallpapers` (not in git, the same path as on Arch), with
thumbnails in `~/.cache/wallpaper-thumbs`. Effects (`Option+Shift+W`) use
ImageMagick on the original of the current wallpaper. The shuffle sets a
random wallpaper every 30 minutes; `hs.settings` keeps it on across
restarts. The OmniWM border colour is fixed in `settings.toml`; wallust does
not change it.

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

### Claude Code notifications

The `claude` package stows `~/.claude/settings.json` and
`~/.local/bin/claude-notify` on both machines. The settings run
`claude-notify` on the `Notification` and `Stop` hook events,
asynchronously. It reads the hook JSON and shows "Claude Code · <project>":
the question or permission text, or "Finished". macOS: through Hammerspoon
(`hammerspoon://claude-notify`), with a sound for questions; a click brings
kitty to the front. Linux: `notify-send`, critical for questions. The
installers create `~/.claude` before stow, so only `settings.json` is a link
and Claude Code's history and caches stay out of git. If Claude Code ever
replaces the link with a plain file (for example after `/config`), copy the
change into `claude/.claude/settings.json` and run `stow -R claude`.

### Login apps

`com.noman.login-apps` (launchd, stowed) starts Slack and Stickies in the
background at login: Slack sends no notifications while it is closed, and
Stickies is the `sticky --autostart` of Arch.

### Known problems (2026-10-10)

- Zen starts without its extensions and its compact mode shortcut until
  you click in it once. It happens with every way of opening Zen.
- YouTube links in the music menu can fail with HTTP 429; yt-dlp is
  rate-limited. The radio streams play.
- tmux keeps running through a logout. Its server and everything in it stay
  in the old login session, where `lsappinfo` sees no apps. Save with
  prefix + Ctrl-s and run `tmux kill-server` after a login.
- Claude Code's image paste (`Ctrl+V`) can stop working in a long session;
  restarting Claude fixes it.
- The Raycast deeplinks come from community documentation, not from
  Raycast's own list. See above if one stops working.

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
