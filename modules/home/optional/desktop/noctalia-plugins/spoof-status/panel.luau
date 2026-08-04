local info = nil
local revealed = false
local redacted = "••••••••••••••"

function onOpen()
    panel.render(ui.column({ padding = 16 }, {
        ui.label({ text = "Loading..." }),
    }))

    noctalia.runAsync(
        "printf '%s\\n%s\\n%s\\n%s\\n%s' "
        .. "\"$(test -f /run/spoof-enabled && echo yes || echo no)\" "
        .. "\"$(cat /run/spoof-hostname 2>/dev/null || hostname)\" "
        .. "\"$(cat /etc/hostname 2>/dev/null)\" "
        .. "\"$(cat /sys/class/net/wl*/address 2>/dev/null | head -1 || echo N/A)\" "
        .. "\"$(ip link show $(ls /sys/class/net/ | grep ^wl | head -1) 2>/dev/null | grep -oP 'permaddr \\K[^ ]+' || cat /sys/class/net/wl*/address 2>/dev/null | head -1 || echo N/A)\"",
        function(result)
            local lines = {}
            for line in result.stdout:gmatch("[^\n]+") do
                table.insert(lines, line)
            end
            info = {
                active = lines[1] == "yes",
                spoof_host = lines[2] or "N/A",
                real_host = lines[3] or "N/A",
                current_mac = lines[4] or "N/A",
                real_mac = lines[5] or "N/A",
            }
            render()
        end
    )
end

function render()
    if not info then return end

    panel.render(ui.column({ gap = 14, paddingLeft = 16, paddingRight = 16, paddingTop = 16, paddingBottom = 24 }, {
        ui.row({ align = "center", justify = "space_between" }, {
            ui.label({ text = "Network Identity", fontSize = 16, fontWeight = "bold" }),
            ui.button({ glyph = "close", variant = "ghost", onClick = "onCloseClicked" }),
        }),
        ui.row({ align = "center", justify = "space_between" }, {
            ui.label({
                text = info.active and "Anonymity Active" or "Anonymity Inactive",
                color = info.active and "primary" or "error",
                fontWeight = "bold",
            }),
            ui.toggle({ checked = info.active, onChange = "onToggleChanged" }),
        }),
        ui.column({ gap = 4 }, {
            ui.row({ align = "center", justify = "space_between" }, {
                ui.label({ text = "Hostname", fontSize = 12, color = "secondary" }),
                ui.button({ glyph = revealed and "eye" or "eye-off", variant = "ghost", onClick = "onRevealClicked" }),
            }),
            ui.row({ justify = "space_between" }, {
                ui.label({ text = "Current" }),
                ui.label({ text = (info.active or revealed) and info.spoof_host or redacted }),
            }),
            ui.row({ justify = "space_between" }, {
                ui.label({ text = "Real" }),
                ui.label({ text = revealed and info.real_host or redacted }),
            }),
        }),
        ui.column({ gap = 4 }, {
            ui.label({ text = "MAC Address", fontSize = 12, color = "secondary" }),
            ui.row({ justify = "space_between" }, {
                ui.label({ text = "Current" }),
                ui.label({ text = (info.active or revealed) and info.current_mac or redacted }),
            }),
            ui.row({ justify = "space_between" }, {
                ui.label({ text = "Real" }),
                ui.label({ text = revealed and info.real_mac or redacted }),
            }),
        }),
    }))
end

function onRevealClicked()
    revealed = not revealed
    render()
end

function onToggleChanged()
    noctalia.runAsync("systemctl start toggle-spoof", function()
        onOpen()
    end)
end

function onCloseClicked()
    panel.close()
end
