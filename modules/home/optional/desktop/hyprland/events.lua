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
-- Restore internal display when external monitor is removed
------------------------------------------------------------
-- The catch-all rule in monitors.lua handles extending to external
-- monitors automatically. This handler only needs to recover from
-- the case where the lid is closed (eDP-1 disabled) and the external
-- monitor is unplugged — leaving no active displays.

local function refresh_bar()
    hl.timer(function()
        hl.exec_cmd("noctalia-shell ipc call bar hideBar")
        hl.timer(function()
            hl.exec_cmd("noctalia-shell ipc call bar showBar")
        end, { timeout = 200, type = "oneshot" })
    end, { timeout = 300, type = "oneshot" })
end

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
        refresh_bar()
    end, { timeout = 500, type = "oneshot" })
end)
