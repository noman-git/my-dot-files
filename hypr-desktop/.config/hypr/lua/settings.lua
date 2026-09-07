-- Main Hyprland settings.
-- See https://wiki.hypr.land/configuring/core/config-options/

local util = require("lua/util")

hl.config({
    dwindle = {
        preserve_split = true,
        -- smart_split = true,
        special_scale_factor = 0.8,
    },

    master = {
        new_status = "master",
        new_on_top = true,
        mfact = 0.5,
    },

    general = {
        resize_on_border = true,
        layout = "dwindle",
    },

    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        repeat_rate = 50,
        repeat_delay = 300,

        sensitivity = 0,
        -- accel_profile: flat, adaptive, or unset for the libinput default
        numlock_by_default = true,
        left_handed = false,
        follow_mouse = 1,
        float_switch_override_focus = false,

        touchpad = {
            disable_while_typing = true,
            natural_scroll = true,
            clickfinger_behavior = false,
            middle_button_emulation = false,
            tap_to_click = true,
            drag_lock = false,
        },

        -- For touchscreens.
        touchdevice = {
            enabled = true,
        },

        tablet = {
            transform = 0,
            left_handed = false,
        },
    },

    gestures = {
        workspace_swipe_distance = 500,
        workspace_swipe_invert = true,
        workspace_swipe_min_speed_to_force = 30,
        workspace_swipe_cancel_ratio = 0.5,
        workspace_swipe_create_new = true,
        workspace_swipe_forever = true,
        -- workspace_swipe_use_r = true,
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        vrr = 2,
        mouse_move_enables_dpms = true,
        enable_swallow = false,
        swallow_regex = "^(kitty)$",
        initial_workspace_tracking = 0,
        middle_click_paste = false,
        enable_anr_dialog = true, -- Application Not Responding
        anr_missed_pings = 15,    -- the default of 1 is too low
        allow_session_lock_restore = true, -- stops the lockscreen crashing on resume

        -- Follow windows that request activation (notifications, "open link
        -- in browser", Slack message clicks) and jump to the workspace where
        -- the window opened. This was misc.focus_on_activate = true in
        -- UserConfigs/UserSettings.conf, overriding the false default.
        focus_on_activate = true,
    },

    -- opengl = {
    --     nvidia_anti_flicker = true,
    -- },

    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles = true,
        pass_mouse_when_bound = false,
    },

    -- Helps when scaling, to avoid pixelating.
    xwayland = {
        enabled = true,
        force_zero_scaling = true,
    },

    render = {
        direct_scanout = 0,
    },

    cursor = {
        sync_gsettings_theme = true,
        no_hardware_cursors = true,
        enable_hyprcursor = true,
        warp_on_change_workspace = 2,
        no_warps = true,
    },
})

-- Touchpad gestures.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- 4-finger up/down zooms the desktop. This was two shell pipelines calling
-- hyprctl keyword and awk; it is now done in Lua.
hl.gesture({ fingers = 4, direction = "up", action = util.zoom(1.5) })
hl.gesture({ fingers = 4, direction = "down", action = util.zoom(1 / 1.5) })

hl.gesture({
    fingers = 3,
    direction = "up",
    action = function()
        hl.exec_cmd(util.scripts .. "/OverviewToggle.sh")
    end,
})
