function update()
    noctalia.setUpdateInterval(5000)
    noctalia.runAsync("test -f /run/spoof-enabled && echo yes || echo no", function(result)
        if result.stdout:match("yes") then
            barWidget.setGlyph("shield")
        else
            barWidget.setGlyph("shield-off")
        end
    end)
end

function onClick()
    noctalia.togglePanel("local/spoof-status:info")
end
