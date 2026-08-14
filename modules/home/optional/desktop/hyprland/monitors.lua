local ctx = require("context")

-- Check physical lid state from ACPI
local function is_lid_closed()
    local f = io.open("/proc/acpi/button/lid/LID0/state", "r")
    if not f then return false end
    local state = f:read("*l")
    f:close()
    return state and state:match("closed") ~= nil
end

local function find_external_monitor()
    local h = io.popen("ls -d /sys/class/drm/card*-* 2>/dev/null")
    if not h then return nil end
    for dir in h:lines() do
        local connector = dir:match("card%d+-(.+)$")
        if connector and not connector:match("^eDP") and connector ~= "Writeback-1" then
            local sf = io.open(dir .. "/status", "r")
            if sf then
                local st = sf:read("*l")
                sf:close()
                if st == "connected" then
                    h:close()
                    return connector
                end
            end
        end
    end
    h:close()
    return nil
end

if ctx.hostname == "framework-16" then
    local ext = find_external_monitor()

    -- External monitors at native resolution
    hl.monitor({
        output = "",
        mode = "preferred",
        position = "auto",
        scale = 1,
    })
    -- Internal display mirrors the external when one is connected
    local edp = {
        output = "eDP-1",
        mode = "preferred",
        position = "auto",
        scale = 1.25,
        disabled = is_lid_closed(),
    }
    if ext then
        edp.mirror = ext
    end
    hl.monitor(edp)

    -- Reduced mouse sensitivity for Framework trackpad
    hl.config({
        input = {
            sensitivity = -0.25,
        },
    })

    -- Lid switch: disable display and backlight when closed
    hl.bind("switch:on:Lid Switch", function()
        hl.monitor({ output = "eDP-1", disabled = true })
        hl.exec_cmd("brightnessctl -d amdgpu_bl1 set 0")
        hl.timer(function()
            hl.exec_cmd("hyprctl reload")
        end, { timeout = 500, type = "oneshot" })
    end, { locked = true })

    hl.bind("switch:off:Lid Switch", function()
        hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.25, disabled = false })
        hl.exec_cmd("brightnessctl -d amdgpu_bl1 set 100%")
        hl.timer(function()
            hl.exec_cmd("hyprctl reload")
        end, { timeout = 500, type = "oneshot" })
    end, { locked = true })

elseif ctx.hostname == "my-thinkpad" then
    -- Native resolution, no scaling
    hl.monitor({
        output = "",
        mode = "preferred",
        position = "auto",
        scale = 1,
    })

else
    -- Fallback: default scale
    hl.monitor({
        output = "",
        mode = "preferred",
        position = "auto",
        scale = ctx.default_scale,
    })
end
