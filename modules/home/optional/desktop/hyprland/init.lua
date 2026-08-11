-- Hyprland Lua configuration entry point.
-- Each require() runs in its own error scope — a bug in one file
-- won't prevent the others from loading.

-- Load plugins before config so their settings and dispatchers are available.
local ctx = require("context")
for _, path in pairs(ctx.plugins) do
    hl.plugin.load(path)
end

require("settings")
require("monitors")
require("rules")
require("binds")
require("autostart")
require("events")
