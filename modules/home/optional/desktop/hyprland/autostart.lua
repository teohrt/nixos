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
hl.config({
    env = {
        XCURSOR_SIZE = "24",
        XCURSOR_THEME = "Adwaita",
        HYPRCURSOR_SIZE = "24",
        HYPRCURSOR_THEME = "Adwaita",
        NIXOS_OZONE_WL = "1",
        QT_QPA_PLATFORM = "wayland;xcb",
    },
})
