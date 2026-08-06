local ctx = require("context")

hl.config({
    general = {
        gaps_in = 7,
        gaps_out = 15,
        border_size = 1,
        col = {
            active_border = "rgba(" .. ctx.colors.base0D:sub(2) .. "ff)",
            inactive_border = "rgba(" .. ctx.colors.base0D:sub(2) .. "ff)",
        },
        layout = "dwindle",
    },

    misc = {
        focus_on_activate = true,
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },

    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        repeat_rate = 50,
        repeat_delay = 300,
        touchpad = {
            disable_while_typing = false,
        },
    },

    decoration = {
        rounding = 10,
        blur = {
            enabled = true,
            size = 6,
            passes = 4,
            vibrancy = 0.2,
            contrast = 1.1,
            noise = 0.02,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
        special_scale_factor = 0.9,
    },

    xwayland = {
        force_zero_scaling = true,
    },
})

-- Animation curves
hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("quick",        { type = "bezier", points = { {0.15, 0}, {0.1, 1} } })

hl.animation({ leaf = "windowsIn",   enabled = true, speed = 1.2, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 0.8, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 1,   bezier = "quick" })
hl.animation({ leaf = "fade",        enabled = true, speed = 1,   bezier = "quick" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 1.1, bezier = "easeOutQuint", style = "slidefade 20%" })
hl.animation({ leaf = "layers",      enabled = true, speed = 1.1, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "layersIn",    enabled = true, speed = 1.1, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "layersOut",   enabled = true, speed = 0.7, bezier = "quick",        style = "slide" })
