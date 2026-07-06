local ctx = require("context")

hl.on("hyprland.start", function()
    -- Desktop shell (bar, launcher, notifications, OSD, lock screen)
    hl.exec_cmd("noctalia")

    -- Auth agent for privilege escalation prompts
    hl.exec_cmd(ctx.bin.polkit_agent)

end)

-- Environment variables
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Adwaita")
hl.env("NIXOS_OZONE_WL", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
