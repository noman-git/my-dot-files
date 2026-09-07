-- Environment variables.
-- See https://wiki.hypr.land/configuring/core/environment-variables/

hl.env("DOTS_VERSION", "2.3.19")

-- Toolkit backends
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("CLUTTER_BACKEND", "wayland")

-- Run SDL2 applications on Wayland. Set to x11 if older SDL games break.
-- hl.env("SDL_VIDEODRIVER", "wayland")

-- XDG
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_MENU_PREFIX", "arch-")

-- Qt
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_QUICK_CONTROLS_STYLE", "org.hyprland.style")

-- Xwayland scale fix. Match the value to the scale set in monitors.lua.
hl.env("GDK_SCALE", "1")
hl.env("QT_SCALE_FACTOR", "1")

-- Cursor. Needs the hyprcursor version of the theme installed.
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("MOZ_ENABLE_WAYLAND", "1")

-- Electron >28: auto picks Wayland when possible, X11 otherwise.
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- NVIDIA
-- Hybrid setup: the Intel iGPU is primary, prime-run drives the 4060 on
-- demand. Setting these globally pins every app to the dGPU, so they stay off.
-- hl.env("LIBVA_DRIVER_NAME", "nvidia")
-- hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
-- hl.env("NVD_BACKEND", "direct")
hl.env("GSK_RENDERER", "ngl")

-- Extra NVIDIA variables. Activate with care.
-- hl.env("GBM_BACKEND", "nvidia-drm")
-- hl.env("__GL_GSYNC_ALLOWED", "1")          -- adaptive Vsync
-- hl.env("__NV_PRIME_RENDER_OFFLOAD", "1")
-- hl.env("__VK_LAYER_NV_optimus", "NVIDIA_only")
-- hl.env("WLR_DRM_NO_ATOMIC", "1")

-- Software rendering, for VMs. May make Hyprland crash.
-- hl.env("LIBGL_ALWAYS_SOFTWARE", "1")
-- hl.env("WLR_RENDERER_ALLOW_SOFTWARE", "1")

-- Firefox on NVIDIA. See github.com/elFarto/nvidia-vaapi-driver#configuration
-- hl.env("MOZ_DISABLE_RDD_SANDBOX", "1")
-- hl.env("EGL_PLATFORM", "wayland")

-- Aquamarine
-- hl.env("AQ_TRACE", "1")                    -- verbose logging
-- hl.env("AQ_DRM_DEVICES", "/dev/dri/card1:/dev/dri/card0")
-- hl.env("AQ_MGPU_NO_EXPLICIT", "1")
-- hl.env("AQ_NO_MODIFIERS", "1")

-- Hyprland
-- hl.env("HYPRLAND_TRACE", "1")
-- hl.env("HYPRLAND_NO_RT", "1")
-- hl.env("HYPRLAND_NO_SD_NOTIFY", "1")
-- hl.env("HYPRLAND_NO_SD_VARS", "1")
