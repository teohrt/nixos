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
-- Auto-focus sole window on workspace
------------------------------------------------------------
-- When a layer surface closes (clipboard panel, launcher, etc.) and the
-- workspace has exactly one window with no active window, refocus it so
-- keyboard input reaches the right place (e.g. clipboard paste).

local function refocus_sole_window()
    if hl.get_active_window() ~= nil then return end

    local ws = hl.get_active_workspace()
    if ws == nil then return end

    local windows = hl.get_workspace_windows(ws.id)
    if windows == nil then return end

    local target = nil
    for _, w in ipairs(windows) do
        if w.title ~= "hyprmon" and w.title ~= "webcam" then
            if target then return end
            target = w
        end
    end

    if target then
        hl.dispatch(hl.dsp.focus({ window = "address:" .. target.address }))
    end
end

hl.on("layer.closed", function()
    hl.timer(refocus_sole_window, { timeout = 50, type = "oneshot" })
end)

------------------------------------------------------------
-- Restore internal display when external monitor is removed
------------------------------------------------------------
hl.on("monitor.removed", function(monitor)
    -- Ignore removal of internal display (lid close)
    if monitor.name:sub(1, 3) == "eDP" then return end

    -- Re-enable eDP-1 unconditionally — it may be disabled from lid close
    hl.timer(function()
        hl.monitor({
            output = "eDP-1",
            mode = "preferred",
            position = "auto",
            scale = ctx.default_scale,
        })
    end, { timeout = 500, type = "oneshot" })
end)
