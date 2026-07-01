-- MONITORS
hl.monitor({ output = "desc:ASUSTek COMPUTER INC VG249Q3A S5LMTF021455", mode = "1920x1080@180", position = "0x0",    scale = "1" })
hl.monitor({ output = "desc:Acer Technologies Acer H236HL LX1AA0044210", mode = "1920x1080@60",  position = "1920x0", scale = "1" })
hl.monitor({ output = "eDP-1",                                            mode = "2560x1600@165", position = "3840x0", scale = "1.33" })
hl.monitor({ output = "desc:ASUSTek COMPUTER INC VA27D N3LMQS036497",    mode = "1920x1080@60",  position = "5765x0", scale = "1" })
hl.monitor({ output = "desc:ASUSTek COMPUTER INC VA27D N3LMQS036502",    mode = "1920x1080@60",  position = "7685x0", scale = "1" })
hl.monitor({ output = "",                                                  mode = "preferred",     position = "auto",   scale = "auto" })

-- PROGRAMS
local terminal    = "wezterm"
local fileManager = "dolphin"
local menu        = "~/.config/hypr/scripts/bemenu-custom-run"
local screenshot  = "~/.config/hypr/scripts/screenshot"

-- AUTOSTART
hl.on("hyprland.start", function()
    -- Propagate Wayland env to systemd/dbus so xdg-desktop-portal-hyprland
    -- has WAYLAND_DISPLAY when it activates (fixes intermittent screenshare)
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("swaync")
    hl.exec_cmd("seaf-cli start")
    hl.exec_cmd("jellyfin-mpv-shim")
end)

hl.on("window.open", function(win)
    if win.class == "mpv" then
        hl.exec_cmd("hyprctl dispatch focuswindow class:mpv")
    end
end)

hl.on("window.close", function(win)
    if win.class == "mpv" then
        local jellyfin = hl.get_windows({ class = "org.jellyfin.JellyfinDesktop" })
        if #jellyfin > 0 then
            hl.exec_cmd("hyprctl dispatch focuswindow class:org.jellyfin.JellyfinDesktop")
        end
    end
end)

-- ENVIRONMENT
hl.env("XCURSOR_THEME",           "macOS")
hl.env("XCURSOR_SIZE",            "24")
hl.env("HYPRCURSOR_THEME",        "macOS")
hl.env("HYPRCURSOR_SIZE",         "24")
hl.env("LIBVA_DRIVER_NAME",       "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

-- CONFIG
hl.config({
    general = {
        gaps_in  = 3,
        gaps_out = 5,

        border_size = 1,

        col = {
            active_border   = "rgba(c28b2ccc)",
            inactive_border = "rgba(3a3a3aaa)",
        },

        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 1,
        rounding_power = 1,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },

        blur = {
            enabled  = true,
            size     = 1,
            passes   = 1,
            vibrancy = 1.0,
        },
    },

    animations = { enabled = true },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 1,
        disable_hyprland_logo   = true,
        enable_swallow          = true,
        swallow_regex           = "^org\\.wezfurlong\\.wezterm$",
    },

    cursor = {
        no_hardware_cursors = 2,
    },

    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        repeat_rate  = 50,
        repeat_delay = 300,

        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- CURVES
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

-- ANIMATIONS
hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default"                            })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint"                       })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint"                       })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint",  style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",         style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear"                       })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear"                       })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick"                              })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint"                       })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint",   style = "fade"      })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",          style = "fade"      })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear"                       })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear"                       })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear",   style = "fade"      })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear",   style = "fade"      })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear",   style = "fade"      })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick"                              })

-- GESTURE
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- DEVICE
hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })

-- KEYBINDINGS
local mainMod = "ALT"

hl.bind(mainMod .. " + Return",           hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + Return",   hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + Q",               hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + BackSpace", hl.dsp.exit())
hl.bind(mainMod .. " + E",               hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SHIFT + space",   hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R",               hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P",               hl.dsp.window.pseudo())
hl.bind(mainMod .. " + SHIFT + F",       hl.dsp.window.fullscreen())

-- Focus (hjkl)
hl.bind(mainMod .. " + Tab", hl.dsp.focus({ workspace = "previous" }), { release = true })
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left"  }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "up"    }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "down"  }))

-- Resize (capital H/L = ALT+SHIFT+h/l)
-- hl.bind(mainMod .. " + L", hl.dsp.window.resize("40 0"))
-- hl.bind(mainMod .. " + H", hl.dsp.window.resize("-40 0"))

-- Workspaces
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scroll workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media / brightness
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),        { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),    { locked = true })

-- Screenshot
hl.bind("Print", hl.dsp.exec_cmd(screenshot))
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(screenshot))

-- Gaps
hl.bind(mainMod .. " + SHIFT + u", hl.dsp.exec_cmd("~/.config/hypr/scripts/gaps.sh dec"), { locked = true, repeating = true })
hl.bind(mainMod .. " + SHIFT + i", hl.dsp.exec_cmd("~/.config/hypr/scripts/gaps.sh inc"), { locked = true, repeating = true })

local function client_exists(class)
    for _, window in ipairs(hl.get_windows()) do
        if window.class == class then
            return true
        end
    end
    return false
end

local function register_singleton(class, command, workspace)
    hl.window_rule({
        match     = { class = class },
        workspace = tostring(workspace),
    })
    return function()
        if not client_exists(class) then
            hl.exec_cmd(command)
        end
        hl.dispatch(hl.dsp.focus({ workspace = workspace }))
    end
end

hl.bind(mainMod .. " + S", register_singleton("steam",                       "steam",    1000))
hl.bind(mainMod .. " + w", register_singleton("Slack",                       "slack",     998))
hl.bind(mainMod .. " + n", register_singleton("spotify",                     "spotify",   996))

-- Media → workspace 999 (MPV if playing, else Jellyfin)
local focus_jellyfin = register_singleton("org.jellyfin.JellyfinDesktop", "jellyfin-desktop", 999)
hl.window_rule({ match = { class = "mpv" }, workspace = "999" })

hl.bind(mainMod .. " + m", function()
    local mpv = hl.get_windows({ class = "mpv" })
    if #mpv > 0 then
        hl.exec_cmd("hyprctl dispatch focuswindow class:mpv")
        hl.dispatch(hl.dsp.focus({ workspace = 999 }))
    else
        focus_jellyfin()
    end
end)

-- WINDOW RULES
hl.window_rule({
    name      = "pavu-float",
    match     = { tag = "waybar-sound" },
    tag       = "+1",
    float     = true,
    size      = "500 300",
    pin       = true,
    animation = "slide",
    rounding  = 5,
    move      = "monitor_w-window_w-20 50",
})

hl.window_rule({
    name   = "zoom-annotate-toolbar",
    match  = { class = "zoom", title = "annotate_toolbar" },
    float  = true,
    size   = "50 50",
    pin    = true,
    move   = "20 monitor_h-window_h-100",
})

