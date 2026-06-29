local ctx = require("context")

-- Check physical lid state from ACPI
local function is_lid_closed()
    local f = io.open("/proc/acpi/button/lid/LID0/state", "r")
    if not f then return false end
    local state = f:read("*l")
    f:close()
    return state and state:match("closed") ~= nil
end

if ctx.hostname == "framework-16" then
    -- Internal display at 1.25x scale (disabled if lid is closed)
    hl.monitor({
        output = "eDP-1",
        mode = "preferred",
        position = "auto",
        scale = 1.25,
        disabled = is_lid_closed(),
    })
    -- External monitors at native resolution
    hl.monitor({
        output = "",
        mode = "preferred",
        position = "auto",
        scale = 1,
    })

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
    end, { locked = true })

    hl.bind("switch:off:Lid Switch", function()
        hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.25, disabled = false })
        hl.exec_cmd("brightnessctl -d amdgpu_bl1 set 100%")
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
