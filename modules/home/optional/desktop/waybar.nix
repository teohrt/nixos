# Waybar status bar: workspaces, clock, battery, wifi, cpu, memory, bluetooth, audio.
# Click handlers open TUI popups (impala, bluetui, pulsemixer) in floating windows.
{ pkgs, config, ... }:

let
  popupBg = config.lib.stylix.colors.base01;

  # Creates a toggle script: closes window if open, opens if closed.
  # Used by waybar click handlers for TUI popups (wifi, bluetooth, audio, etc.)
  toggleBtop = pkgs.writeShellScript "toggle-btop" ''
    if hyprctl clients -j | ${pkgs.jq}/bin/jq -e '.[] | select(.class == "floating-btop")' > /dev/null 2>&1; then
      hyprctl dispatch closewindow "class:^(floating-btop)$"
    else
      kitty -o 'background=#${popupBg}' -o background_opacity=1 --class floating-btop -e btop &
      sleep 0.15
      read -r width height < <(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[0] | "\(.width / .scale / 2 | floor) \(.height / .scale / 2 | floor)"')
      hyprctl dispatch resizeactive exact "$width" "$height"
      hyprctl dispatch centerwindow
    fi
  '';

  mkToggle = title: openCmd: pkgs.writeShellScript "toggle-${title}" ''
    if hyprctl clients -j | ${pkgs.jq}/bin/jq -e '.[] | select(.title == "${title}")' > /dev/null 2>&1; then
      hyprctl dispatch closewindow "title:^(${title})$"
    else
      ${openCmd} &
      sleep 0.15
      read -r width height < <(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[0] | "\(.width / .scale / 2 | floor) \(.height / .scale / 2 | floor)"')
      hyprctl dispatch resizeactive exact "$width" "$height"
      hyprctl dispatch centerwindow
    fi
  '';


  # CPU usage calculation: samples /proc/stat twice (1s apart) to compute
  # per-core and total utilization. Outputs JSON with usage % and load average.
  cpuAwk = pkgs.writeText "waybar-cpu.awk" ''
    BEGIN {
      while ((getline line < "/proc/stat") > 0) {
        if (line ~ /^cpu/) {
          split(line, a, " ")
          nm = a[1]
          tot1[nm] = a[2]+a[3]+a[4]+a[5]+a[6]+a[7]+a[8]
          idl1[nm] = a[5]
          order[++nc] = nm
        }
      }
      close("/proc/stat")
      system("sleep 1")
      while ((getline line < "/proc/stat") > 0) {
        if (line ~ /^cpu/) {
          split(line, a, " ")
          nm = a[1]
          tot2 = a[2]+a[3]+a[4]+a[5]+a[6]+a[7]+a[8]
          idl2 = a[5]
          dt = tot2 - tot1[nm]
          di = idl2 - idl1[nm]
          pct[nm] = dt > 0 ? (dt - di) / dt * 100 : 0
        }
      }
      getline lavg < "/proc/loadavg"
      split(lavg, la, " ")
      # load_pct: 1-minute load average (average number of processes waiting for
      # CPU time) normalized to core count (nc-1 excludes the aggregate "cpu"
      # entry). 100% means all cores fully saturated on average.
      load_pct = la[1] / (nc - 1) * 100
      # pct["cpu"]: fraction of CPU time spent doing work in the last sample
      # interval (idle time subtracted from total). Instantaneous, not averaged.
      tooltip = sprintf("CPU\\nUsage: %.2f%%  Load: %.1f%%", pct["cpu"], load_pct)
      for (i = 2; i <= nc; i++)
        tooltip = tooltip sprintf("\\n%s: %.2f%%", order[i], pct[order[i]])
      num = sprintf(" %.2f%%", pct["cpu"])
      pad = 8 - length(num)
      spaces = ""
      for (i = 0; i < pad; i++) spaces = spaces " "
      printf "{\"text\": \"%s<span size='200%%' color='#${config.lib.stylix.colors.base0B}'>󰍛</span><span rise='3500' size='130%%' color='#${config.lib.stylix.colors.base0B}'>%s</span>\", \"tooltip\": \"%s\"}\n", spaces, num, tooltip
      exit
    }
  '';

  cpuScript = pkgs.writeShellScript "waybar-cpu" ''
    awk -f ${cpuAwk}
  '';

  # Memory usage from /proc/meminfo. Shows used %, total, and available RAM.
  memScript = pkgs.writeShellScript "waybar-mem" ''
    awk '
      /MemTotal/     { total = $2 }
      /MemAvailable/ { avail  = $2 }
      END {
        used = total - avail
        pct  = used / total * 100
        num = sprintf(" %.2f%%", pct)
        pad = 8 - length(num); spaces = ""
        for (i = 0; i < pad; i++) spaces = spaces " "
        printf "{\"text\": \"%s<span size=\\\"200%%\\\" color=\\\"#${config.lib.stylix.colors.base0A}\\\">󰘚</span><span rise=\\\"3500\\\" size=\\\"130%%\\\" color=\\\"#${config.lib.stylix.colors.base0A}\\\">%s</span>\", \"tooltip\": \"RAM\\n%.2f%%  %.1fGB / %.1fGB\\nAvail: %.1fGB\"}\n",
          spaces, num, pct, used/1024/1024, total/1024/1024, avail/1024/1024
      }
    ' /proc/meminfo
  '';

  # CPU temperature from hwmon sensor. Tries k10temp (AMD) and coretemp (Intel).
  # Finds hwmon dynamically since the number can change between boots.
  tempScript = pkgs.writeShellScript "waybar-temp" ''
    # Try common CPU temp sensors: k10temp (AMD), coretemp (Intel)
    for sensor in k10temp coretemp; do
      for hwmon in /sys/class/hwmon/hwmon*/; do
        if [[ "$(cat "$hwmon/name" 2>/dev/null)" == "$sensor" ]]; then
          temp=$(cat "$hwmon/temp1_input" 2>/dev/null)
          break 2
        fi
      done
    done

    if [[ -z "$temp" ]]; then
      echo '{"text": "", "tooltip": "No temp sensor"}'
      exit
    fi

    # Convert millidegrees to Celsius
    temp_c=$((temp / 1000))

    # Icon/color based on temperature
    if   [[ $temp_c -ge 80 ]]; then icon="󰸁"; class="critical"
    elif [[ $temp_c -ge 60 ]]; then icon="󰔏"; class="warm"
    else                            icon="󰔏"; class="normal"
    fi

    text="<span size='150%'>$icon</span> <span rise='2000' size='130%'>''${temp_c}°C</span>"
    temp_f=$(( temp_c * 9 / 5 + 32 ))
    printf '{"text": "%s", "tooltip": "CPU: %d°F", "class": "%s"}\n' "$text" "$temp_f" "$class"
  '';

  # Waybar's built-in network module reads signal strength from NetworkManager,
  # which uses a different dBm-to-percentage formula than iwd. This script reads
  # RSSI directly from iwctl (same source as impala) and applies impala's formula
  # (>= -50 dBm = 100%, else 2 * (100 + RSSI)) so the displayed percentage matches.
  wifiScript = pkgs.writeShellScript "waybar-wifi" ''
    # Check if wifi is blocked by rfkill
    if rfkill list wifi | grep -q "Soft blocked: yes"; then
      echo '{"text": "<span size=\"200%\" color=\"#${config.lib.stylix.colors.base0B}\">󰤭</span>", "tooltip": "wifi off", "class": "off"}'
      exit
    fi

    IFACE=$(for dev in /sys/class/net/*/wireless; do
      [ -d "$dev" ] && basename "$(dirname "$dev")" && break
    done)

    if [ -z "$IFACE" ]; then
      echo '{"text": "<span size=\"200%\" color=\"#${config.lib.stylix.colors.base0B}\">󰤭</span>", "tooltip": "disconnected", "class": "disconnected"}'
      exit
    fi

    INFO=$(${pkgs.iwd}/bin/iwctl station "$IFACE" show 2>/dev/null)
    SSID=$(echo "$INFO" | awk '/Connected network/{sub(/.*Connected network[[:space:]]+/, ""); sub(/[[:space:]]*$/, ""); print}')
    RSSI=$(echo "$INFO" | awk '$1 == "RSSI" {print $2}')

    if [ -z "$SSID" ]; then
      echo '{"text": "<span size=\"200%\" color=\"#${config.lib.stylix.colors.base0B}\">󰤭</span>", "tooltip": "disconnected", "class": "disconnected"}'
      exit
    fi

    # impala formula: >= -50 dBm = 100%, else 2 * (100 + RSSI)
    # https://github.com/pythops/impala/blob/1f0f04f45c9722e7f4d2922f98dadaa0e7c92255/src/mode/station.rs#L494-L498
    PCT=$(awk -v r="$RSSI" 'BEGIN {
      p = (r >= -50) ? 100 : 2 * (100 + r)
      if (p < 0) p = 0
      print p
    }')

    # Bandwidth from /proc/net/dev (sleep 1 to compute per-second rate)
    RX1=$(awk -F'[: ]+' "/^ *$IFACE:/{print \$3}" /proc/net/dev)
    TX1=$(awk -F'[: ]+' "/^ *$IFACE:/{print \$11}" /proc/net/dev)
    sleep 1
    RX2=$(awk -F'[: ]+' "/^ *$IFACE:/{print \$3}" /proc/net/dev)
    TX2=$(awk -F'[: ]+' "/^ *$IFACE:/{print \$11}" /proc/net/dev)

    RX_BITS=$(( (RX2 - RX1) * 8 ))
    TX_BITS=$(( (TX2 - TX1) * 8 ))

    fmt_bits() {
      awk -v b="$1" -v dir="$2" 'BEGIN {
        if      (b >= 1000000000) { v = b / 1000000000; u = "Gb/s"; w = 6; d = 3 }
        else if (b >= 100000)     { v = b / 1000000;    u = "Mb/s"; w = 6; d = 3 }
        else if (b >= 1000)       { v = b / 1000;       u = "Kb/s"; w = 6; d = 3 }
        else                      { v = b;              u = "b/s "; w = 6; d = 3 }
        if (v == 0) {
          num = sprintf("%*s0", w - 1, "")
        } else {
          num = sprintf("%0*.*f", w, 2, v)
          for (i = 1; i <= d; i++) {
            if (substr(num, i, 1) == "0") num = substr(num, 1, i-1) " " substr(num, i+1)
            else break
          }
        }
        printf "<b>%s</b>%s %s", dir, num, u
      }'
    }

    TX_FMT=$(fmt_bits "$TX_BITS" "↑")
    RX_FMT=$(fmt_bits "$RX_BITS" "↓")

    if   [ "$PCT" -ge 90 ]; then ICON="󰤨"
    elif [ "$PCT" -ge 60 ]; then ICON="󰤥"
    elif [ "$PCT" -ge 30 ]; then ICON="󰤢"
    else                         ICON="󰤟"
    fi

    if   [ "''${PCT}" -lt 10  ]; then PCT_PAD="  "
    elif [ "''${PCT}" -lt 100 ]; then PCT_PAD=" "
    else                               PCT_PAD=""
    fi
    TEXT="<span size='200%' color='#${config.lib.stylix.colors.base0D}'>$ICON</span>  <span rise='3500' size='130%' font_family='monospace'><span color='#${config.lib.stylix.colors.base0D}'>''${PCT}%''${PCT_PAD}</span>  <span color='#${config.lib.stylix.colors.base0A}'>''${TX_FMT}</span>  <span color='#${config.lib.stylix.colors.base0B}'>''${RX_FMT}</span></span>"
    TOOLTIP="''${SSID}"

    printf '{"text": "%s", "tooltip": "%s"}\n' "$TEXT" "$TOOLTIP"
  '';

  # Shows red camera icon when wf-recorder is running
  recordingScript = pkgs.writeShellScript "waybar-recording" ''
    if pgrep -x wf-recorder > /dev/null; then
      echo '{"text": "󰻃", "tooltip": "Recording... click to stop", "class": "recording"}'
    else
      echo '{"text": ""}'
    fi
  '';

  # Stops recording and shows notification with option to open
  stopRecordingScript = pkgs.writeShellScript "stop-recording" ''
    file=$(cat /tmp/current-recording 2>/dev/null)
    rm -f /tmp/current-recording
    pkill -INT wf-recorder
    sleep 0.2
    pkill -RTMIN+8 waybar
    # Run notification in background so script exits immediately
    if [[ -n "$file" ]]; then
      (sleep 0.5 && if [[ -f "$file" ]]; then
        action=$(${pkgs.libnotify}/bin/notify-send -u low -a "Recording" \
          "Recording saved" "$file" \
          --action="open=Open")
        [[ "$action" == "open" ]] && xdg-open "$file"
      fi) &
    fi
  '';

in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = [{
      layer = "top";
      position = "bottom";
      height = 24;
      margin-top = 0;
      margin-left = 0;
      margin-right = 0;
      spacing = 0;

      modules-left = [ "hyprland/workspaces" "custom/recording" ];
      modules-center = [ "battery" "clock" "custom/notification" ];
      modules-right = [ "custom/wifi" "custom/temp" "custom/cpu" "custom/mem" "bluetooth" "pulseaudio" ];

      "custom/launcher" = {
        format = "󱄅";
        on-click = "walker -N -H";
        tooltip = false;
      };

      "custom/recording" = {
        exec = "echo '{\"text\": \"󰻃\", \"tooltip\": \"Recording... click to stop\", \"class\": \"recording\"}'";
        exec-if = "pgrep -x wf-recorder";
        return-type = "json";
        interval = 1;
        signal = 8;
        on-click = "${stopRecordingScript}";
      };

      "custom/notification" = {
        exec = "swaync-client -swb";
        return-type = "json";
        format = "<span size=\"200%\">{icon}</span>";
        format-icons = {
          notification = "󰂚";
          none = "󰂜";
          dnd-notification = "󰂛";
          dnd-none = "󰂛";
        };
        on-click = "swaync-client -t -sw";       # toggle notification panel
        on-click-right = "swaync-client -d -sw"; # toggle do not disturb
        escape = true;
        tooltip = false;
      };

      "hyprland/workspaces" = {
        format = "<span size=\"130%\">{id}</span>";
        on-scroll-up = "hyprctl dispatch workspace e+1";
        on-scroll-down = "hyprctl dispatch workspace e-1";
      };

      clock = {
        format = "<span size=\"130%\">{:%I:%M %p}</span>";
        tooltip-format = "{:%A: %m/%d/%Y}";
      };

      battery = {
        format-high = "<span size=\"150%\">{icon}</span>";
        format-medium = "<span size=\"150%\">{icon}</span>";
        format-low = "<span size=\"150%\">{icon}</span> <span color=\"#${config.lib.stylix.colors.base0D}\" size=\"130%\">{capacity}%</span>";
        format-critical = "<span size=\"150%\">{icon}</span> <span color=\"#${config.lib.stylix.colors.base0D}\" size=\"130%\">{capacity}%</span>";
        format-charging-high = "<span size=\"150%\">󰂄</span>";
        format-charging-medium = "<span size=\"150%\">󰂄</span>";
        format-charging-low = "<span size=\"150%\">󰂄</span> <span color=\"#${config.lib.stylix.colors.base0D}\" size=\"130%\">{capacity}%</span>";
        format-charging-critical = "<span size=\"150%\">󰂄</span> <span color=\"#${config.lib.stylix.colors.base0D}\" size=\"130%\">{capacity}%</span>";
        tooltip-format = "{capacity}%";
        format-icons = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
        states = { critical = 15; low = 25; medium = 50; high = 100; };
        interval = 2;
        on-click = "${mkToggle "battery" "kitty -o 'background=#${popupBg}' -o background_opacity=1 --title battery -e ${pkgs.batmon}/bin/batmon"}";
      };

      "custom/temp" = {
        exec = "${tempScript}";
        return-type = "json";
        interval = 5;
      };

      "custom/cpu" = {
        exec = "${cpuScript}";
        return-type = "json";
        interval = 2;
        on-click = "${toggleBtop}";
      };

      "custom/mem" = {
        exec = "${memScript}";
        return-type = "json";
        interval = 2;
        on-click = "${toggleBtop}";
      };

      "custom/wifi" = {
        exec = "${wifiScript}";
        return-type = "json";
        interval = 1;
        on-click = "${mkToggle "wifi" "rfkill unblock wifi && kitty -o 'background=#${popupBg}' -o background_opacity=1 --title wifi -e impala"}";
        on-click-right = "rfkill toggle wifi";
      };

      bluetooth = {
        format = "<span size=\"150%\">󰂯</span>";
        format-connected = "<span size=\"150%\">󰂱</span> <span size=\"130%\">{device_alias}</span>";
        format-connected-battery = "<span size=\"150%\">󰂱</span> <span size=\"130%\">{device_alias} {device_battery_percentage}%</span>";
        format-disabled = "<span size=\"150%\">󰂲</span>";
        format-off = "<span size=\"150%\">󰂲</span>";
        tooltip-format-connected = "{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias} ({device_address})";
        tooltip-format-enumerate-connected-battery = "{device_alias} ({device_address}) {device_battery_percentage}%";
        on-click = "${mkToggle "bluetooth" "rfkill unblock bluetooth && kitty -o 'background=#${popupBg}' -o background_opacity=1 --title bluetooth -e bluetui"}";
        on-click-right = "rfkill toggle bluetooth";
      };

      pulseaudio = {
        format = "<span size=\"200%\">󰕾</span>";
        format-muted = "<span size=\"200%\">󰖁</span>";
        tooltip-format = "{volume}%";
        on-click = "${mkToggle "audio" "kitty -o 'background=#${popupBg}' -o background_opacity=1 --title audio -e wiremix"}";
        on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      };


      "custom/power" = {
        format = "<span size=\"200%\">⏻</span>";
        on-click = "power-menu";
        tooltip = false;
      };

    }];

    style = ''
      * {
        font-family: "JetBrains Mono", monospace;
        font-size: 12px;
        border: none;
        border-radius: 0;
        min-height: 0;
        background: transparent;
      }



      window#waybar {
        background: rgba(13, 15, 20, 0.7);
        border-radius: 0;
        padding: 0;
        color: #${config.lib.stylix.colors.base0D};
      }

      window#waybar * {
        opacity: 1;
      }


      .modules-left,
      .modules-center,
      .modules-right {
        padding: 0;
      }

      #custom-launcher,
      #custom-wifi,
      #custom-notification,
      #battery,
      #bluetooth,
      #pulseaudio,
      #custom-power {
        border-radius: 0;
        border: none;
        margin: 0;
      }

      #custom-launcher {
        padding: 2px 16px;
        font-size: 22px;
      }

      #custom-launcher:hover,
      #clock:hover,
      #custom-wifi:hover,
      #custom-notification:hover,
      #battery:hover,
      #bluetooth:hover,
      #pulseaudio:hover,
      #custom-temp:hover,
      #custom-cpu:hover,
      #custom-mem:hover,
      #custom-power:hover {
        background: rgba(255, 255, 255, 0.08);
        border-radius: 0;
        margin: 0;
      }

      #workspaces {
        background: transparent;
        padding: 0;
        margin: 0;
      }

      #workspaces button {
        padding: 2px 16px;
        color: #${config.lib.stylix.colors.base0D};
        box-shadow: none;
        border-radius: 0;
        border: none;
        background: transparent;
        margin: 0;
        transition: all 0.2s ease;
      }

      #workspaces button.active {
        padding: 2px 16px;
        color: #000000;
        background: #${config.lib.stylix.colors.base0D};
        border-radius: 0;
        margin: 0;
      }

      .modules-left #workspaces button,
      .modules-center #workspaces button,
      .modules-right #workspaces button {
        border-bottom: none;
      }

      .modules-left #workspaces button.active,
      .modules-left #workspaces button.focused,
      .modules-center #workspaces button.active,
      .modules-center #workspaces button.focused,
      .modules-right #workspaces button.active,
      .modules-right #workspaces button.focused {
        border-bottom: none;
      }

      #workspaces button:hover {
        background: rgba(255, 255, 255, 0.08);
      }

      #clock {
        padding: 2px 13px 2px 15px;
        color: #ffffff;
      }

      #battery {
        padding: 2px 16px;
      }

      #custom-wifi {
        padding: 2px 14px 2px 12px;
      }

      #custom-wifi.off,
      #custom-wifi.disconnected {
        color: #${config.lib.stylix.colors.base03};
      }

      #custom-temp {
        padding: 2px 7px 2px 12px;
      }

      #custom-cpu,
      #custom-mem {
        padding: 2px 7px;
      }

      #custom-temp.warm     { color: #ffaa44; }
      #custom-temp.critical { color: #ff4444; }

      #pulseaudio {
        padding: 2px 14px;
      }
      #pulseaudio.muted {
        padding: 2px 14px;
        color: #${config.lib.stylix.colors.base03};
      }

      #custom-notification {
        padding: 2px 16px;
      }

      #custom-notification.dnd-none,
      #custom-notification.dnd-notification {
        color: #${config.lib.stylix.colors.base03};
      }

      #bluetooth {
        padding: 2px 16px;
      }

      #bluetooth.off,
      #bluetooth.disabled {
        padding: 2px 16px;
        color: #${config.lib.stylix.colors.base03};
      }


      #custom-power {
        padding: 2px 16px 2px 16px;
        font-size: 18px;
      }

      tooltip {
        background: rgba(10, 10, 15, 0.85);
        border: none;
        border-radius: 8px;
        color: #${config.lib.stylix.colors.base0D};
        font-size: 30px;
        padding: 4px 8px;
      }

      #battery.critical { color: #ff4444; }
      #battery.low      { color: #ffaa44; }
      #battery.medium   { color: #ffdd44; }
      #battery.high     { color: #${config.lib.stylix.colors.base0D}; }

      #custom-recording {
        padding: 0;
        margin: 0;
      }

      #custom-recording.recording {
        padding: 2px 12px;
        background: rgba(255, 68, 68, 0.3);
        border-radius: 0;
        margin: 0;
        color: #ff4444;
        font-size: 16px;
      }

    '';
  };

  # Auto-restart waybar on crash. Increased restart tolerance because waybar
  # may start before Hyprland is fully ready and fail a few times at login.
  # Default is 5 restarts in 10 seconds, which is too aggressive for login timing.
  systemd.user.services.waybar = {
    Unit = {
      StartLimitBurst = 10;        # allow 10 restarts...
      StartLimitIntervalSec = 30;  # ...within 30 seconds before giving up
    };
    Service = {
      Restart = "on-failure";
      RestartSec = 1;
    };
  };
}
