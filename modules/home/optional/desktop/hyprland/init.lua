-- Hyprland Lua configuration entry point.
-- Each require() runs in its own error scope — a bug in one file
-- won't prevent the others from loading.

-- Load plugins before config so their settings and dispatchers are available.
local ctx = require("context")
for _, path in pairs(ctx.plugins) do
    hl.plugin.load(path)
end

local dir = os.getenv("HOME") .. "/.config/hypr/"
for entry in io.popen("ls " .. dir .. "*.lua"):lines() do
    local name = entry:match("([^/]+)%.lua$")
    if name and name ~= "hyprland" then
        require(name)
    end
end
