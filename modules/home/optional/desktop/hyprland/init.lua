-- Hyprland Lua configuration entry point.
-- Each require() runs in its own error scope — a bug in one file
-- won't prevent the others from loading.
require("settings")
require("monitors")
require("rules")
require("binds")
require("autostart")
require("events")
