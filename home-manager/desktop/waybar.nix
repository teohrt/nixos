{ pkgs, ... }:

let
  mkToggle = title: openCmd: pkgs.writeShellScript "toggle-${title}" ''
    if hyprctl clients -j | ${pkgs.jq}/bin/jq -e '.[] | select(.title == "${title}")' > /dev/null 2>&1; then
      hyprctl dispatch closewindow "title:^(${title})$"
    else
      ${openCmd}
    fi
  '';

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
      printf "{\"text\": \"%s<span size='large'>󰘚</span>%s\", \"tooltip\": \"%s\"}\n", spaces, num, tooltip
      exit
    }
  '';

  cpuScript = pkgs.writeShellScript "waybar-cpu" ''
    awk -f ${cpuAwk}
  '';

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
        printf "{\"text\": \"%s<span size=\\\"large\\\">󰻠</span>%s\", \"tooltip\": \"RAM\\n%.2f%%  %.1fGB / %.1fGB\\nAvail: %.1fGB\"}\n",
          spaces, num, pct, used/1024/1024, total/1024/1024, avail/1024/1024
      }
    ' /proc/meminfo
  '';

  # Waybar's built-in network module reads signal strength from NetworkManager,
  # which uses a different dBm-to-percentage formula than iwd. This script reads
  # RSSI directly from iwctl (same source as impala) and applies impala's formula
  # (>= -50 dBm = 100%, else 2 * (100 + RSSI)) so the displayed percentage matches.
  wifiScript = pkgs.writeShellScript "waybar-wifi" ''
    IFACE=$(for dev in /sys/class/net/*/wireless; do
      [ -d "$dev" ] && basename "$(dirname "$dev")" && break
    done)

    if [ -z "$IFACE" ]; then
      echo '{"text": "<span size=\"large\">󰤭</span>", "tooltip": "disconnected", "class": "disconnected"}'
      exit
    fi

    INFO=$(${pkgs.iwd}/bin/iwctl station "$IFACE" show 2>/dev/null)
    SSID=$(echo "$INFO" | awk '/Connected network/{sub(/.*Connected network[[:space:]]+/, ""); sub(/[[:space:]]*$/, ""); print}')
    RSSI=$(echo "$INFO" | awk '$1 == "RSSI" {print $2}')

    if [ -z "$SSID" ]; then
      echo '{"text": "<span size=\"large\">󰤭</span>", "tooltip": "disconnected", "class": "disconnected"}'
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
        if (b >= 1000000) { num = sprintf("%.1f", b/1000000); unit = "Mb/s" }
        else              { num = sprintf("%.0f", b/1000);    unit = "Kb/s" }
        pad = 4 - length(num)
        spaces = ""
        for (i = 0; i < pad; i++) spaces = spaces " "
        printf "%s%s%s %s", spaces, dir, num, unit
      }'
    }

    TX_FMT=$(fmt_bits "$TX_BITS" "↑")
    RX_FMT=$(fmt_bits "$RX_BITS" "↓")

    if   [ "$PCT" -ge 75 ]; then ICON="󰤨"
    elif [ "$PCT" -ge 50 ]; then ICON="󰤥"
    elif [ "$PCT" -ge 25 ]; then ICON="󰤢"
    else                         ICON="󰤟"
    fi

    if   [ "''${PCT}" -lt 10  ]; then PCT_PAD="  "
    elif [ "''${PCT}" -lt 100 ]; then PCT_PAD=" "
    else                               PCT_PAD=""
    fi
    TEXT="<span size='large'>$ICON</span> ''${PCT}%''${PCT_PAD} <span color='#ffffff99'>''${TX_FMT}</span> <span color='#ffffff99'>''${RX_FMT}</span>"
    TOOLTIP="''${SSID}"

    printf '{"text": "%s", "tooltip": "%s"}\n' "$TEXT" "$TOOLTIP"
  '';

  weatherScript = pkgs.writeShellScript "waybar-weather" ''
    WEATHER=$(${pkgs.curl}/bin/curl -sf "https://api.open-meteo.com/v1/forecast?latitude=40.7128&longitude=-74.0060&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code&temperature_unit=fahrenheit&wind_speed_unit=mph")
    if [ -z "$WEATHER" ]; then
      echo '{"text": "󰖑 --", "tooltip": "Weather unavailable"}'
      exit
    fi

    CODE=$(echo "$WEATHER" | ${pkgs.jq}/bin/jq -r '.current.weather_code')
    TEMP=$(echo "$WEATHER" | ${pkgs.jq}/bin/jq -r '.current.temperature_2m | round')
    FEELS=$(echo "$WEATHER" | ${pkgs.jq}/bin/jq -r '.current.apparent_temperature | round')
    HUMIDITY=$(echo "$WEATHER" | ${pkgs.jq}/bin/jq -r '.current.relative_humidity_2m')
    WIND=$(echo "$WEATHER" | ${pkgs.jq}/bin/jq -r '.current.wind_speed_10m | round')

    case $CODE in
      0)                     ICON="󰖙" DESC="Clear" ;;
      1|2)                   ICON="󰖕" DESC="Partly cloudy" ;;
      3)                     ICON="󰖐" DESC="Overcast" ;;
      45|48)                 ICON="󰖑" DESC="Fog" ;;
      51|53|55|56|57)        ICON="󰖗" DESC="Drizzle" ;;
      61|63|65|66|67)        ICON="󰖗" DESC="Rain" ;;
      71|73|75|77)           ICON="󰖘" DESC="Snow" ;;
      80|81|82)              ICON="󰖗" DESC="Showers" ;;
      85|86)                 ICON="󰖘" DESC="Snow showers" ;;
      95|96|99)              ICON="󰖓" DESC="Thunderstorm" ;;
      *)                     ICON="!" DESC="Unknown" ;;
    esac

    TEXT="<span color='#ffffff'>$ICON ''${TEMP}°F</span>"
    TOOLTIP="$DESC\nFeels like: ''${FEELS}°F\nHumidity: ''${HUMIDITY}%\nWind: ''${WIND} mph"

    echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\"}"
  '';
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = [{
      layer = "top";
      position = "top";
      height = 32;
      margin-top = 6;
      margin-left = 4;
      margin-right = 4;
      spacing = 8;

      modules-left = [ "custom/launcher" "hyprland/workspaces" "custom/weather" ];
      modules-center = [ "battery" "clock" "custom/notification" ];
      modules-right = [ "custom/wifi" "custom/cpu" "custom/mem" "pulseaudio" "bluetooth" "custom/power" ];

      "custom/launcher" = {
        format = "󱄅";
        on-click = "walker -N -H";
        tooltip = false;
      };

      "custom/notification" = {
        exec = "swaync-client -swb";
        return-type = "json";
        format = "{icon}";
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
        format = "{id}";
        on-scroll-up = "hyprctl dispatch workspace e+1";
        on-scroll-down = "hyprctl dispatch workspace e-1";
      };

      clock = {
        format = "{:%I:%M %p}";
        tooltip-format = "{:%A: %m/%d/%Y}";
      };

      battery = {
        format = "<span size=\"large\">{icon}</span> <span color=\"#ffffff\">{capacity}%</span>";
        format-charging = "<span size=\"large\">󰂄</span> <span color=\"#ffffff\">{capacity}%</span>";
        format-icons = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
        states = { critical = 20; low = 40; medium = 70; high = 100; };
        interval = 2;
        on-click = "${mkToggle "battop" "alacritty --title battop -e battop"}";
      };

      "custom/cpu" = {
        exec = "${cpuScript}";
        return-type = "json";
        interval = 2;
      };

      "custom/mem" = {
        exec = "${memScript}";
        return-type = "json";
        interval = 2;
      };

      "custom/wifi" = {
        exec = "${wifiScript}";
        return-type = "json";
        interval = 2;
        on-click = "${mkToggle "wifi" "rfkill unblock wifi && alacritty --title wifi -e impala"}";
      };

      bluetooth = {
        format = "<span size=\"large\">󰂯</span>";
        format-connected = "<span size=\"large\">󰂱</span> {device_alias}";
        format-connected-battery = "<span size=\"large\">󰂱</span> {device_alias} {device_battery_percentage}%";
        format-disabled = "<span size=\"large\">󰂲</span>";
        tooltip-format-connected = "{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias} ({device_address})";
        tooltip-format-enumerate-connected-battery = "{device_alias} ({device_address}) {device_battery_percentage}%";
        on-click = "${mkToggle "bluetooth" "rfkill unblock bluetooth && alacritty --title bluetooth -e bluetui"}";
      };

      pulseaudio = {
        format = "<span size=\"xx-large\">󰕾</span>";
        format-muted = "<span size=\"xx-large\">󰝟</span>";
        tooltip-format = "{volume}%";
        on-click = "${mkToggle "audio" "alacritty --title audio -e wiremix"}";
      };

      "custom/power" = {
        format = "<span size=\"large\">⏻</span>";
        on-click = "power-menu";
        tooltip = false;
      };


      "custom/weather" = {
        exec = "${weatherScript}";
        return-type = "json";
        interval = 300;
        tooltip = true;
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
        color: #ffffff;
      }


      window#waybar {
        background: transparent;
        border-radius: 16px;
      }

      .modules-left,
      .modules-center,
      .modules-right {
        padding: 0 4px;
      }

      #custom-launcher,
      #custom-wifi,
      #custom-notification,
      #battery,
      #bluetooth,
      #pulseaudio,
      #custom-power {
        background: rgba(255, 255, 255, 0.18);
        border-radius: 20px;
        margin: 3px 0;
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
      #custom-cpu:hover,
      #custom-mem:hover,
      #custom-weather:hover,
      #custom-power:hover {
        background: rgba(255, 255, 255, 0.08);
        border-radius: 20px;
        margin: 3px 0;
      }

      #workspaces {
        background: transparent;
        padding: 3px 5px;
      }

      #workspaces button {
        padding: 2px 7px;
        color: #b3b3b3;
        box-shadow: none;
        border-radius: 20px;
        background: transparent;
        margin: 0 2px;
        transition: all 0.2s ease;
      }

      #workspaces button.active {
        padding: 2px 22px;
        color: #ffffff;
        background: rgba(255, 255, 255, 0.18);
        border-radius: 20px;
      }

      #workspaces button:hover {
        background: rgba(255, 255, 255, 0.08);
      }

      #clock {
        padding: 2px 13px 2px 15px;
      }

      #battery {
        padding: 2px 16px;
      }

      #custom-wifi {
        padding: 2px 8px 2px 6px;
      }

      #custom-cpu,
      #custom-mem,
      #custom-weather {
        padding: 2px 7px;
      }

      #pulseaudio {
        padding: 2px 16px;
      }

      #custom-notification {
        padding: 2px 16px;
        font-size: 18px;
      }

      #bluetooth {
        padding: 2px 16px;
      }

      #custom-power {
        padding: 2px 16px 2px 16px;
        font-size: 18px;
      }

      tooltip {
        background: rgba(10, 10, 15, 0.85);
        border: none;
        border-radius: 8px;
        color: #ffffff;
        padding: 4px 8px;
      }

      #battery.critical { color: #ff4444; }
      #battery.low      { color: #ffaa44; }
      #battery.medium   { color: #ffdd44; }
      #battery.high     { color: #ffffff; }

      #pulseaudio.muted {
        color: rgba(255, 255, 255, 0.3);
      }

    '';
  };
}
