{ pkgs, ... }:

let
  mkToggle = title: openCmd: pkgs.writeShellScript "toggle-${title}" ''
    if hyprctl clients -j | ${pkgs.jq}/bin/jq -e '.[] | select(.title == "${title}")' > /dev/null 2>&1; then
      hyprctl dispatch closewindow "title:^(${title})$"
    else
      ${openCmd}
    fi
  '';

  cpuScript = pkgs.writeShellScript "waybar-cpu" ''
    read1=$(awk '/^cpu / {printf "%d %d", $2+$3+$4+$5+$6+$7+$8, $5}' /proc/stat)
    sleep 1
    read2=$(awk '/^cpu / {printf "%d %d", $2+$3+$4+$5+$6+$7+$8, $5}' /proc/stat)
    load=$(awk '{print $1}' /proc/loadavg)
    awk -v r1="$read1" -v r2="$read2" -v load="$load" 'BEGIN {
      split(r1, a, " "); split(r2, b, " ")
      dtotal = b[1] - a[1]; didle = b[2] - a[2]
      usage = (dtotal - didle) / dtotal * 100
      printf "{\"text\": \"󰘚 %.2f%%\", \"tooltip\": \"CPU\\n%.2f%%  Load: %s\"}\n", usage, usage, load
    }'
  '';

  memScript = pkgs.writeShellScript "waybar-mem" ''
    awk '
      /MemTotal/     { total = $2 }
      /MemAvailable/ { avail  = $2 }
      END {
        used = total - avail
        pct  = used / total * 100
        printf "{\"text\": \"󰻠 %.2f%%\", \"tooltip\": \"RAM\\n%.2f%%  %.1fGB / %.1fGB\\nAvail: %.1fGB\"}\n",
          pct, pct, used/1024/1024, total/1024/1024, avail/1024/1024
      }
    ' /proc/meminfo
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

    TEXT="$ICON ''${TEMP}°F"
    TOOLTIP="$DESC\nFeels like: ''${FEELS}°F\nHumidity: ''${HUMIDITY}%\nWind: ''${WIND} mph"

    echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\"}"
  '';
in
{
  programs.waybar = {
    enable = true;

    settings = [{
      layer = "top";
      position = "top";
      height = 32;
      margin-top = 6;
      margin-left = 4;
      margin-right = 4;
      spacing = 8;

      modules-left = [ "custom/launcher" "custom/weather" "hyprland/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [ "custom/cpu" "custom/mem" "network" "bluetooth" "pulseaudio" "battery" "custom/power" ];

      "custom/launcher" = {
        format = "󱄅";
        on-click = "walker -N -H";
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
        format = "󰚥 {capacity}%";
        format-charging = "󱐋 {capacity}%";
        interval = 2;
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

      network = {
        format-wifi = "󰤨";
        format-disconnected = "󰤭";
        tooltip-format-wifi = "{essid}  {signalStrength}%\n↑ {bandwidthUpBits}  ↓ {bandwidthDownBits}";
        tooltip-format-disconnected = "disconnected";
        on-click = "${mkToggle "wifi" "rfkill unblock wifi && alacritty --title wifi -e impala"}";
      };

      bluetooth = {
        format = "󰂯";
        format-connected = "󰂱";
        format-disabled = "󰂲";
        tooltip-format = "{controller_alias}\n{num_connections} connected";
        tooltip-format-connected = "{controller_alias}\n{num_connections} connected\n{device_enumerate}";
        tooltip-format-enumerate-connected = "  {device_alias}";
        on-click = "${mkToggle "bluetooth" "rfkill unblock bluetooth && alacritty --title bluetooth -e bluetui"}";
      };

      pulseaudio = {
        format = "󰕾";
        format-muted = "󰝟";
        tooltip-format = "{volume}%: {desc}";
        on-click = "${mkToggle "audio" "alacritty --title audio -e wiremix"}";
      };

      "custom/power" = {
        format = "⏻";
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
      }

      .modules-left,
      .modules-center,
      .modules-right {
        padding: 0 4px;
      }

      #custom-launcher {
        background: rgba(10, 10, 15, 0.85);
        border-radius: 12px;
        padding: 0 16px 0 12px;
        font-size: 16px;
      }

      #custom-launcher:hover,
      #clock:hover,
      #battery:hover,
      #network:hover,
      #bluetooth:hover,
      #pulseaudio:hover,
      #custom-cpu:hover,
      #custom-mem:hover,
      #custom-weather:hover,
      #custom-power:hover {
        background: rgba(126, 186, 228, 0.15);
      }

      #workspaces {
        background: rgba(10, 10, 15, 0.85);
        border-radius: 20px;
        padding: 3px 5px;
      }

      #workspaces button {
        padding: 2px 7px;
        color: rgba(255, 255, 255, 0.5);
        box-shadow: none;
        border-radius: 20px;
        background: rgba(255, 255, 255, 0.08);
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
        background: rgba(255, 255, 255, 0.13);
      }

      #clock,
      #battery {
        background: rgba(10, 10, 15, 0.85);
        border-radius: 12px;
        padding: 0 13px 0 15px;
      }

      #network {
        background: rgba(10, 10, 15, 0.85);
        border-radius: 12px;
        padding: 0 16px 0 12px;
      }

      #battery,
      #bluetooth,
      #pulseaudio,
      #custom-cpu,
      #custom-mem,
      #custom-weather {
        background: rgba(10, 10, 15, 0.85);
        border-radius: 12px;
        padding: 0 14px;
      }

      #custom-power {
        background: rgba(10, 10, 15, 0.85);
        border-radius: 12px;
        padding: 0 16px 0 12px;
      }

      tooltip {
        background: rgba(10, 10, 15, 0.85);
        border: none;
        border-radius: 8px;
        color: #ffffff;
        padding: 4px 8px;
      }

      #pulseaudio.muted {
        color: rgba(255, 255, 255, 0.3);
      }
    '';
  };
}
