local mod = "SUPER"
local ipc = "noctalia msg"

---- Terminal in current directory ----
-- Finds the shell child of the focused terminal and opens kitty in its cwd.
-- The window.open handler in rules.lua floats kitty when it's alone on a workspace.
local shell_names = { zsh = true, bash = true, fish = true, nu = true }

local function find_shell_cwd(pid)
    -- Read direct children from /proc
    local cf = io.open("/proc/" .. pid .. "/task/" .. pid .. "/children", "r")
    if not cf then return nil end
    local children_str = cf:read("*a")
    cf:close()

    for child in children_str:gmatch("%d+") do
        -- Check if child is a shell
        local comm_f = io.open("/proc/" .. child .. "/comm", "r")
        if comm_f then
            local comm = comm_f:read("*l")
            comm_f:close()
            if comm and shell_names[comm] then
                local lf = io.popen("readlink /proc/" .. child .. "/cwd")
                if lf then
                    local cwd = lf:read("*l")
                    lf:close()
                    if cwd and cwd ~= "" then return cwd end
                end
            end
        end
        -- Check grandchildren (e.g. kitty -> shell -> child)
        local gcf = io.open("/proc/" .. child .. "/task/" .. child .. "/children", "r")
        if gcf then
            local gc_str = gcf:read("*a")
            gcf:close()
            for grandchild in gc_str:gmatch("%d+") do
                local gc_comm_f = io.open("/proc/" .. grandchild .. "/comm", "r")
                if gc_comm_f then
                    local gc_comm = gc_comm_f:read("*l")
                    gc_comm_f:close()
                    if gc_comm and shell_names[gc_comm] then
                        local lf = io.popen("readlink /proc/" .. grandchild .. "/cwd")
                        if lf then
                            local cwd = lf:read("*l")
                            lf:close()
                            if cwd and cwd ~= "" then return cwd end
                        end
                    end
                end
            end
        end
    end
    return nil
end

---- Window management ----
hl.bind(mod .. " + Return", function()
    local dir = os.getenv("HOME")
    local w = hl.get_active_window()
    if w and w.pid then
        local cwd = find_shell_cwd(tostring(w.pid))
        if cwd then
            dir = cwd
        end
    end
    hl.exec_cmd("kitty --directory '" .. dir:gsub("'", "'\\''") .. "'")
end, { description = "Terminal" })
hl.bind(mod .. " + Escape",       hl.dsp.exec_cmd(ipc .. " panel-toggle session"), { description = "Session menu" })
hl.bind(mod .. " + SHIFT + Return", hl.dsp.exec_cmd("google-chrome-stable"), { description = "Browser" })
hl.bind(mod .. " + F",            hl.dsp.window.fullscreen({ mode = "maximized" }), { description = "Maximize" })
hl.bind(mod .. " + SHIFT + F", function()
    local w = hl.get_active_window()
    if w and w.class == "google-chrome" then
        if w.fullscreen_client == 0 then
            hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 0, client = 2 }))
        else
            hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 0, client = 0 }))
        end
    end
end, { description = "Toggle Chrome top bar" })
hl.bind(mod .. " + SHIFT + SPACE", hl.dsp.exec_cmd("nautilus --new-window"), { description = "File manager" })
hl.bind(mod .. " + Q",            hl.dsp.window.close(), { description = "Close window" })

local gaps_removed = false
hl.bind(mod .. " + G", function()
    gaps_removed = not gaps_removed
    if gaps_removed then
        hl.config({ general = { gaps_in = 0, gaps_out = 0 }, decoration = { rounding = 0 } })
    else
        hl.config({ general = { gaps_in = 7, gaps_out = 15 }, decoration = { rounding = 10 } })
    end
end, { description = "Toggle gaps" })

---- Copy (SUPER+C → CTRL+SHIFT+C in terminals, CTRL+C elsewhere) ----
hl.bind(mod .. " + C", function()
    local w = hl.get_active_window()
    if w and w.class == "kitty" then
        hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL SHIFT", key = "c", window = "activewindow" }))
    else
        hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = "c", window = "activewindow" }))
    end
end, { description = "Copy" })

hl.bind(mod .. " + V",            hl.dsp.exec_cmd(ipc .. " panel-toggle clipboard"), { description = "Clipboard history" })

---- UI toggles ----
hl.bind(mod .. " + SPACE",        hl.dsp.exec_cmd(ipc .. " panel-toggle launcher"), { description = "Launch apps" })
hl.bind(mod .. " + B",            hl.dsp.exec_cmd(ipc .. " bar-toggle"), { description = "Toggle bar" })
hl.bind(mod .. " + SHIFT + B", function()
    local f = io.popen("noctalia config export 2>/dev/null | grep -m1 '^position' | cut -d'\"' -f2")
    local cur = f and f:read("*l") or "top"
    if f then
        f:close()
    end
    local new_pos = cur == "top" and "bottom" or "top"
    local state = os.getenv("HOME") .. "/.local/state/noctalia/settings.toml"
    local content = ""
    local sf = io.open(state, "r")
    if sf then
        content = sf:read("*a")
        sf:close()
    end
    content = content:gsub("%[bar%.main%]\nposition = \"[^\"]+\"\n?", "")
    content = content:gsub("\n+$", "\n")
    local wf = io.open(state, "w")
    if wf then
        wf:write(content .. "\n[bar.main]\nposition = \"" .. new_pos .. "\"\n")
        wf:close()
        os.execute("noctalia msg config-reload")
    end
end, { description = "Move bar top/bottom" })
hl.bind(mod .. " + J",            hl.dsp.layout("togglesplit"), { description = "Toggle split" })
hl.bind(mod .. " + P",            hl.dsp.window.pseudo(), { description = "Pseudo window" })
hl.bind(mod .. " + W",            hl.dsp.exec_cmd(ipc .. " panel-toggle wallpaper"), { description = "Wallpaper picker" })
hl.bind(mod .. " + SHIFT + W",    hl.dsp.exec_cmd(ipc .. " panel-toggle noctalia/wallhaven:browser"), { description = "Wallhaven browser" })


---- Float window (toggle float, resize to half-screen, center) ----
hl.bind(mod .. " + O", function()
    local w = hl.get_active_window()
    if w == nil then return end
    if w.floating then
        hl.dispatch(hl.dsp.window.float({ action = "unset" }))
    else
        local mon = w.monitor
        if mon == nil then return end
        local width = math.floor(mon.width / mon.scale / 2)
        local height = math.floor(mon.height / mon.scale / 2)
        hl.dispatch(hl.dsp.window.float({ action = "set" }))
        hl.dispatch(hl.dsp.window.resize({ x = width, y = height }))
        hl.dispatch(hl.dsp.window.center())
    end
end, { description = "Float window" })

---- Toggle menu (still calls shell script for external tools) ----
hl.bind(mod .. " + T",            hl.dsp.exec_cmd("toggle-menu"), { description = "Toggle menu" })

---- Voice input (still calls shell script) ----
hl.bind(mod .. " + slash",        hl.dsp.exec_cmd("voice-input"), { description = "Voice input" })

---- Screenshot ----
hl.bind(mod .. " + S",            hl.dsp.exec_cmd(ipc .. " screenshot-region"), { description = "Screenshot region" })

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

---- Scratch pad ----
-- Suppress hyprfocus animations when closing the scratchpad so the
-- returning focus doesn't trigger a distracting slide on the main workspace.
local function toggle_scratchpad()
    local special = hl.get_active_special_workspace()
    local closing = special ~= nil and special.name == "special:scratchpad"

    if not closing then
        hl.dispatch(hl.dsp.workspace.toggle_special("scratchpad"))
        return
    end

    hl.config({ plugin = { hyprfocus = { only_on_monitor_change = true } } })
    hl.dispatch(hl.dsp.workspace.toggle_special("scratchpad"))
    hl.config({ plugin = { hyprfocus = { only_on_monitor_change = false } } })
end

for _, ctrl in ipairs({ "Control_L", "Control_R" }) do
    hl.bind(mod .. " + " .. ctrl,           toggle_scratchpad, { description = "Toggle scratch pad" })
    hl.bind(mod .. " + SHIFT + " .. ctrl,   hl.dsp.window.move({ workspace = "special:scratchpad" }), { description = "Move to scratch pad" })
end

---- Media keys (repeating, work while locked) ----
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd(ipc .. " volume-up"), { repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd(ipc .. " volume-down"), { repeating = true, locked = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd(ipc .. " volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd(ipc .. " mic-mute"), { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(ipc .. " brightness-up"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. " brightness-down"), { repeating = true, locked = true })

---- Mouse bindings ----
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
