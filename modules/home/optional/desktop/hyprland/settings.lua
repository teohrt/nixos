local ctx = require("context")

hl.config({
    general = {
        gaps_in = 0,
        gaps_out = 0,
        border_size = 1,
        no_border_on_floating = false,
        col = {
            active_border = "rgba(" .. ctx.colors.base0D:sub(2) .. "ff)",
            inactive_border = "rgba(" .. ctx.colors.base0D:sub(2) .. "ff)",
        },
        layout = "dwindle",
    },

    misc = {
        focus_on_activate = true,
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
        rounding = 0,
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
        pseudotile = true,
        preserve_split = true,
    },

    xwayland = {
        force_zero_scaling = true,
    },
})

-- Animation curves and rules
hl.curve("linear", { 0, 0, 1, 1 })

hl.animation("windowsIn",   { enabled = true, speed = 1.2, curve = "linear" })
hl.animation("windowsOut",  { enabled = true, speed = 1.2, curve = "linear" })
hl.animation("windowsMove", { enabled = true, speed = 1.2, curve = "linear" })
hl.animation("fade",        { enabled = true, speed = 1.2, curve = "linear" })
hl.animation("workspaces",  { enabled = true, speed = 1.2, curve = "linear", style = "fade" })
hl.animation("layers",      { enabled = true, speed = 1.2, curve = "linear", style = "fade" })
hl.animation("layersIn",    { enabled = true, speed = 1.2, curve = "linear", style = "fade" })
hl.animation("layersOut",   { enabled = true, speed = 1.2, curve = "linear", style = "fade" })
