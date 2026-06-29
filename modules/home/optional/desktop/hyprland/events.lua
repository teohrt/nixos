local ctx = require("context")

------------------------------------------------------------
-- Unfloat solo floating kitty when another window joins
------------------------------------------------------------
-- When a new window opens on a workspace that has a solo floating kitty,
-- unfloat the kitty so both windows tile. Complements terminalHere which
-- floats kitty on empty workspaces for a centered single-window look.

hl.on("window.open", function(new_window)
    -- Skip floating helpers that should stay floating
    if new_window.title == "hyprmon" or new_window.title == "webcam" then
        return
    end

    local ws = new_window.workspace
    if ws == nil then return end

    -- Find floating kitty windows on the same workspace and unfloat them
    local windows = hl.get_workspace_windows(ws.id)
    if windows == nil then return end

    for _, w in ipairs(windows) do
        if w.class == "kitty" and w.floating and w.address ~= new_window.address then
            hl.dispatch(hl.dsp.window.float({ action = "unset", window = "address:" .. w.address }))
        end
    end
end)

------------------------------------------------------------
-- Auto-mirror laptop display to external monitor
------------------------------------------------------------
-- When an external monitor connects, mirror the laptop (eDP-*) to it.
-- When it disconnects, restore the internal display.

local function get_internal_name()
    local monitors = hl.get_monitors()
    if monitors == nil then return nil end
    for _, m in ipairs(monitors) do
        if m.name:sub(1, 3) == "eDP" then
            return m.name
        end
    end
    return nil
end

local function get_external_name()
    local monitors = hl.get_monitors()
    if monitors == nil then return nil end
    for _, m in ipairs(monitors) do
        if m.name:sub(1, 3) ~= "eDP" then
            return m.name
        end
    end
    return nil
end

local function refresh_bar()
    hl.timer(function()
        hl.exec_cmd("noctalia-shell ipc call bar hideBar")
        hl.timer(function()
            hl.exec_cmd("noctalia-shell ipc call bar showBar")
        end, { timeout = 200, type = "oneshot" })
    end, { timeout = 300, type = "oneshot" })
end

local function handle_connect()
    local internal = get_internal_name()
    local external = get_external_name()
    if internal == nil or external == nil then return end

    hl.monitor({
        output = external,
        mode = "preferred",
        position = "auto",
        scale = ctx.default_scale,
    })
    hl.monitor({
        output = internal,
        mode = "preferred",
        position = "auto",
        scale = ctx.default_scale,
        mirror = external,
    })
    refresh_bar()
end

local function handle_disconnect()
    local internal = get_internal_name()
    if internal == nil then return end

    hl.monitor({
        output = internal,
        mode = "preferred",
        position = "auto",
        scale = ctx.default_scale,
    })
    refresh_bar()
end

hl.on("monitor.added", function(monitor)
    -- Delay slightly to let the monitor fully initialize
    hl.timer(function()
        handle_connect()
    end, { timeout = 500, type = "oneshot" })
end)

hl.on("monitor.removed", function(monitor)
    -- Only handle removal of external monitors
    if monitor.name:sub(1, 3) == "eDP" then return end
    hl.timer(function()
        handle_disconnect()
    end, { timeout = 500, type = "oneshot" })
end)

-- Re-apply on config reload (NixOS rebuilds regenerate config, clearing runtime state)
hl.on("config.reloaded", function()
    hl.timer(function()
        if get_external_name() ~= nil then
            handle_connect()
        end
    end, { timeout = 500, type = "oneshot" })
end)

-- Handle current state on startup
hl.on("hyprland.start", function()
    hl.timer(function()
        if get_external_name() ~= nil then
            handle_connect()
        end
    end, { timeout = 1000, type = "oneshot" })
end)
