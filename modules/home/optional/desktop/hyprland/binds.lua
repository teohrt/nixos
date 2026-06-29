local mod = "SUPER"

---- Window management ----
hl.bind(mod .. " + Return",       hl.dsp.exec_cmd("terminal-here"), { description = "Terminal" })
hl.bind(mod .. " + Escape",       hl.dsp.exec_cmd("noctalia-shell ipc call sessionMenu toggle"), { description = "Session menu" })
hl.bind(mod .. " + SHIFT + Return", hl.dsp.exec_cmd("google-chrome-stable"), { description = "Browser" })
hl.bind(mod .. " + F",            hl.dsp.window.fullscreen({}), { description = "Fullscreen" })
hl.bind(mod .. " + SHIFT + F",    hl.dsp.exec_cmd("nautilus --new-window"), { description = "File manager" })
hl.bind(mod .. " + Q",            hl.dsp.window.close(), { description = "Close window" })

---- UI toggles ----
hl.bind(mod .. " + SPACE",        hl.dsp.exec_cmd("noctalia-shell ipc call launcher toggle"), { description = "Launch apps" })
hl.bind(mod .. " + B",            hl.dsp.exec_cmd("noctalia-shell ipc call bar toggle"), { description = "Toggle bar" })
hl.bind(mod .. " + J",            hl.dsp.layout("togglesplit"), { description = "Toggle split" })
hl.bind(mod .. " + P",            hl.dsp.window.pseudo(), { description = "Pseudo window" })
hl.bind(mod .. " + SHIFT + W",    hl.dsp.exec_cmd("noctalia-shell ipc call wallpaper toggle"), { description = "Wallpaper picker" })
hl.bind(mod .. " + M",            hl.dsp.exec_cmd("kitty --single-instance --instance-group popup --session none --title hyprmon -e hyprmon"), { description = "Monitor settings" })

---- Pop window (inline — replaces popWindow shell script) ----
hl.bind(mod .. " + O", function()
    local w = hl.get_active_window()
    if w == nil then return end
    if w.pinned then
        hl.dispatch(hl.dsp.window.pin())
        hl.dispatch(hl.dsp.window.float({ action = "unset" }))
    else
        hl.dispatch(hl.dsp.window.float({ action = "set" }))
        hl.dispatch(hl.dsp.window.resize({ x = "50%", y = "50%", relative = true }))
        hl.dispatch(hl.dsp.window.center())
        hl.dispatch(hl.dsp.window.pin())
        hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
    end
end, { description = "Pop window out" })

---- Toggle menu (still calls shell script for external tools) ----
hl.bind(mod .. " + T",            hl.dsp.exec_cmd("toggle-menu"), { description = "Toggle menu" })

---- Voice input (still calls shell script) ----
hl.bind(mod .. " + slash",        hl.dsp.exec_cmd("voice-input"), { description = "Voice input" })

---- Screenshot ----
hl.bind(mod .. " + S",            hl.dsp.exec_cmd("screenshot"), { description = "Screenshot region" })

---- Window resizing ----
hl.bind(mod .. " + minus",        hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { description = "Shrink window" })
hl.bind(mod .. " + equal",        hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { description = "Grow window" })
hl.bind(mod .. " + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { description = "Shrink window vertically" })
hl.bind(mod .. " + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 100, relative = true }), { description = "Grow window vertically" })

---- Focus ----
hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }), { description = "Move focus left" })
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }), { description = "Move focus right" })
hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }), { description = "Move focus up" })
hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }), { description = "Move focus down" })

---- Swap tiles ----
hl.bind(mod .. " + SHIFT + left",  hl.dsp.window.swap({ direction = "left" }), { description = "Swap window left" })
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "right" }), { description = "Swap window right" })
hl.bind(mod .. " + SHIFT + up",    hl.dsp.window.swap({ direction = "up" }), { description = "Swap window up" })
hl.bind(mod .. " + SHIFT + down",  hl.dsp.window.swap({ direction = "down" }), { description = "Swap window down" })

---- Workspaces (loop replaces 20 lines of repetitive bindings) ----
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mod .. " + " .. key,           hl.dsp.focus({ workspace = i }), { description = "Workspace " .. i })
    hl.bind(mod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i }), { description = "Move to workspace " .. i })
end

---- Media keys (repeating, work while locked) ----
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("noctalia-shell ipc call volume increase"), { repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("noctalia-shell ipc call volume decrease"), { repeating = true, locked = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("noctalia-shell ipc call volume muteOutput"), { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("noctalia-shell ipc call volume muteInput"), { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("noctalia-shell ipc call brightness increase"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia-shell ipc call brightness decrease"), { repeating = true, locked = true })

---- Mouse bindings ----
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
