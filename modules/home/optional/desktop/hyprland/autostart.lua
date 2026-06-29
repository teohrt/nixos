local ctx = require("context")

hl.on("hyprland.start", function()
    -- Desktop shell (bar, launcher, notifications, OSD, lock screen)
    hl.exec_cmd("noctalia-shell")

    -- Auth agent for privilege escalation prompts
    hl.exec_cmd(ctx.bin.polkit_agent)

    -- Keep clipboard alive after source process exits
    hl.exec_cmd("wl-clip-persist --clipboard regular")
end)

-- Environment variables
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Adwaita")
hl.env("NIXOS_OZONE_WL", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
