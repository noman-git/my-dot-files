# Hyprland config: hyprlang to Lua

Converted 2026-09-02 on Hyprland 0.56.2.

hyprlang (the `.conf` format) was deprecated in Hyprland 0.55 and is expected to
be removed around 0.57. See https://hypr.land/news/26_lua/

Hyprland reads `hyprland.lua` if it exists, and `hyprland.conf` otherwise. It
checks once at startup.

## What is live

```
hyprland.lua              entry point, requires everything below
lua/util.lua              shared helpers, $var parser, zoom helper
lua/defaults.lua          reads UserConfigs/01-UserDefaults.conf
lua/colors.lua            reads wallust/wallust-hyprland.conf
lua/env.lua               environment variables
lua/settings.lua          input, misc, binds, gestures, layouts
lua/decorations.lua       borders, opacity, shadow, blur
lua/animations.lua        active animation preset
lua/keybinds.lua          default keybinds
lua/userkeybinds.lua      your own keybinds
lua/laptop.lua            laptop keys, touchpad device
lua/windowrules.lua       window and layer rules
lua/startup.lua           autostart
animations-lua/*.lua      18 animation presets
monitors.lua              written by nwg-displays
workspaces.lua            written by nwg-displays
```

## Still hyprlang, on purpose

| File | Why |
| --- | --- |
| `wallust/wallust-hyprland.conf` | wallust rewrites it on every wallpaper change, and `hyprlock.conf` sources it. `lua/colors.lua` parses it. |
| `UserConfigs/01-UserDefaults.conf` | `WaybarScripts.sh`, `RofiSearch.sh` and `Kool_Quick_Settings.sh` read it as shell. `lua/defaults.lua` parses it. |
| `hyprlock.conf`, `hyprlock-2k.conf`, `hypridle.conf` | hyprlock and hypridle are separate programs and still use hyprlang. |
| `application-style.conf` | Read by hyprland-qt-support, not by Hyprland. |
| `monitors.conf`, `workspaces.conf` | nwg-displays writes both formats. Only the `.lua` pair is read. |

## Retired but left in place

`hyprland.conf`, `configs/*.conf`, and the `UserConfigs/*.conf` files other than
`01-UserDefaults.conf` are no longer read. They are left on disk so the rollback
below is one command. `animations/*.conf` are kept for reference; the picker now
uses `animations-lua/`.

A full copy of the pre-conversion tree is in
`~/.config/hypr-conf-backup-20260902-115347/` and as a tarball beside it.

## Rollback

```sh
mv ~/.config/hypr/hyprland.lua ~/.config/hypr/hyprland.lua.disabled
hyprctl dispatch 'hl.dsp.exit()'    # or just reboot
```

Hyprland then loads `hyprland.conf` again. The scripts were changed for the Lua
era though, so to go back fully, restore them:

```sh
cp -a ~/.config/hypr-conf-backup-20260902-115347/scripts ~/.config/hypr/
cp -a ~/.config/hypr-conf-backup-20260902-115347/UserScripts ~/.config/hypr/
```

## hyprctl changed

`hyprctl keyword` does not work with a Lua config: it answers "keyword can't
work with non-legacy parsers. Use eval." `hyprctl setprop` is gone, and
`hyprctl dispatch` now takes Lua.

| Old | New |
| --- | --- |
| `hyprctl keyword decoration:blur:size 2` | `hyprctl eval 'hl.config({ decoration = { blur = { size = 2 } } })'` |
| `hyprctl keyword bind SUPER,O,layoutmsg,togglesplit` | `hyprctl eval 'hl.bind("SUPER + O", hl.dsp.layout("togglesplit"))'` |
| `hyprctl keyword unbind SUPER,O` | `hyprctl eval 'hl.unbind("SUPER + O")'` |
| `hyprctl dispatch workspace 3` | `hyprctl dispatch 'hl.dsp.focus({ workspace = 3 })'` |
| `hyprctl setprop active opaque toggle` | `hyprctl dispatch 'hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" })'` |

`hyprctl getoption` still accepts both `a:b:c` and `a.b.c`. Note that some
options report as `bool` under Lua where they reported as `int` under hyprlang,
so `jq .int` alone is not enough. `GameMode.sh` shows the pattern that handles
both.

Two useful references ship with the package:
`/usr/share/hypr/stubs/hl.meta.lua` (full API types) and
`/usr/share/hypr/hyprland.lua` (worked example).

Check a config without running it:

```sh
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
```

## Scripts changed

`TouchPad.sh`, `ChangeBlur.sh`, `ChangeLayout.sh`, `KeybindsLayoutInit.sh`,
`GameMode.sh`, `Dropterminal.sh`, `SwitchKeyboardLayout.sh`,
`Tak0-Per-Window-Switch.sh`, `Tak0-Autodispatch.sh` (both copies),
`Animations.sh`, `KeyBinds.sh`, `Kool_Quick_Settings.sh`,
`UserScripts/RainbowBorders.sh`.

`KeyBinds.sh` was rewritten to read `hyprctl binds -j` instead of parsing
`.conf` files with awk, so the menu now lists the binds that are actually
active, including ones set at runtime.

`SwitchKeyboardLayout.sh` and `Tak0-Per-Window-Switch.sh` now read
`input:kb_layout` from the compositor instead of grepping `UserSettings.conf`.
Set the layout list in `lua/settings.lua`.

## Differences from the .conf version

1. **Workspace binds use digits, not keycodes.** The `.conf` used `code:10` to
   `code:19`. Hyprland 0.56.2 accepts `code:NN` in a Lua bind string without an
   error but registers keycode 0, so those binds would be dead. This layout is
   `us` only, so the digits sit where the keycodes did. Recheck after a
   Hyprland upgrade.
2. **`xf86AudioPlayPause` was not a real keysym**, so that bind never fired. It
   is now `XF86MediaPlayPause`, which is `KEY_PLAYPAUSE`.
3. **ALT+tab is one bind, not two.** The `.conf` bound cyclenext and
   bringactivetotop separately to the same key. It is now a single Lua function
   doing both, which is the documented idiom.
4. **Three animation presets had out-of-range values.** hyprlang accepted them
   silently; the Lua parser enforces the documented limits. `borderangle` speed
   was clamped from 180 to 100 in `00-default`, `01-default-v2` and
   `Mahaveer-me-2`, and the `nice` bezier in `01-default-v2` had its y values
   clamped into [-1.00, 2.00]. Each clamp is commented in the file.
5. **Desktop zoom is native Lua.** The 4-finger gestures and SUPER+ALT+scroll
   used to shell out to `hyprctl keyword` piped through awk. See `util.zoom`.
6. **`workspaceopt allfloat` has no Lua dispatcher**, so SUPER+ALT+SPACE now
   floats each window on the workspace in a loop.
7. **Every bind has a description.** The laptop binds had none, so they now
   show up in the keybind search menu.
8. **`mouse = true` on the drag/resize mouse binds is vestigial.** `hyprctl
   binds` reports `mouse=false` under Lua and no Lua flag sets that bit, but
   SUPER+left-drag and SUPER+right-drag were both tested on 2026-09-03 and work
   regardless: drag and resize are interactive by nature now. The flag is kept
   because Hyprland's own shipped example config passes it. `mouse=false` in
   hyprctl output is not a fault.

## Verification done

Both configs were booted in nested Hyprland instances and compared:

- 353 config options: no value differences.
- 10 workspace rules: identical.
- 35 animations (speed, curve, style): identical.
- Binds: 124 identical triggers; every remaining difference is one of items 1
  to 3 above.
- All 18 animation presets parse clean.
- Every `hyprctl eval` the patched scripts issue was run against a live Lua
  instance and returned ok, with the values read back.

Confirmed on the real session after the first boot on Lua, 2026-09-03: no
config errors, 159 binds all with descriptions, SUPER+1 to SUPER+0 registered,
all startup apps running, `KeybindsLayoutInit.sh` and `RainbowBorders.sh`
applied their `hyprctl eval` at boot, wallust colours picked up, and
SUPER+drag / SUPER+right-drag both work.
