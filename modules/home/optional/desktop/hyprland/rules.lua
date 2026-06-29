local ctx = require("context")

-- Helper: create a centered floating popup rule set for an app
local function floating_popup(match)
    hl.window_rule({
        match = match,
        float = true,
        size = { "50%", "50%" },
        center = true,
        border_size = 1,
        border_color = "rgba(" .. ctx.colors.base0D:sub(2) .. "ff)",
    })
end

-- Smart gaps: remove borders when only one tiled window on workspace
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })

hl.window_rule({ match = { float = false, workspace = "w[tv1]" }, border_size = 0 })
hl.window_rule({ match = { float = false, workspace = "f[1]" }, border_size = 0 })

-- Default workspace assignments
local workspace_assignments = {
    { class = "^(chromium-browser|google-chrome|Chromium)$", workspace = "1" },
    { class = "^(kitty)$", initial_title = "^(kitty)$",       workspace = "2" },
    { class = "^(code|Code|code-url-handler)$",              workspace = "3" },
    { class = "^(bruno)$",                                     workspace = "4" },
    { class = "^(DBeaver)$",                                   workspace = "4" },
    { class = "^(Slack|slack)$",                                workspace = "6" },
    { class = "^(obsidian)$",                                  workspace = "7" },
    { class = "^(spotify|Spotify)$",                           workspace = "8" },
    { class = "^(zoom)$",                                      workspace = "10" },
}

for _, rule in ipairs(workspace_assignments) do
    local match = { class = rule.class }
    if rule.initial_title then
        match.initial_title = rule.initial_title
    end
    hl.window_rule({ match = match, workspace = rule.workspace })
end

-- Screensaver rules
hl.window_rule({
    match = { class = "^(screensaver)$" },
    fullscreen = true,
    no_anim = true,
    no_dim = true,
    border_size = 0,
})

-- Opacity rules for semi-transparent apps
local transparent_apps = { "org.gnome.Nautilus", "Spotify", "Slack" }
local app_opacity = tostring(ctx.opacity.applications) .. " " .. tostring(ctx.opacity.applications)
for _, class in ipairs(transparent_apps) do
    hl.window_rule({
        match = { class = "^(" .. class .. ")$" },
        opacity = app_opacity,
    })
end

hl.window_rule({
    match = { class = "^(obsidian)$" },
    opacity = "0.9 0.9",
})

-- Floating popup apps
floating_popup({ class = "^(org.kde.partitionmanager)$" })
floating_popup({ class = "^(localsend_app)$" })
floating_popup({ class = "^(1Password)$" })
floating_popup({ class = "^(bruno)$" })
floating_popup({ title = "^(hyprmon)$" })

-- Bruno: suppress maximize persistence
hl.window_rule({
    match = { class = "^(bruno)$" },
    suppress_event = "maximize fullscreen",
})

-- Webcam preview: float, pin, bottom-right corner, no border
hl.window_rule({
    match = { title = "^(webcam)$" },
    float = true,
    size = { 320, 240 },
    move = { "100%-330", "100%-250" },
    pin = true,
    border_size = 0,
})

-- Layer rules
hl.layer_rule({
    match = { namespace = "selection" },
    no_anim = true,
})
