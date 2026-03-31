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
      tooltip = sprintf("CPU\\n%.2f%%  Load: %s", pct["cpu"], la[1])
      for (i = 2; i <= nc; i++)
        tooltip = tooltip sprintf("\\n%s: %.2f%%", order[i], pct[order[i]])
      printf "{\"text\": \"<span size='large'>󰘚</span> %.2f%%\", \"tooltip\": \"%s\"}\n", pct["cpu"], tooltip
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
        printf "{\"text\": \"<span size=\\\"large\\\">󰻠</span> %.2f%%\", \"tooltip\": \"RAM\\n%.2f%%  %.1fGB / %.1fGB\\nAvail: %.1fGB\"}\n",
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

      modules-left = [ "custom/launcher" "hyprland/workspaces" ];
      modules-center = [ "battery" "clock" "custom/weather" ];
      modules-right = [ "custom/cpu" "custom/mem" "bluetooth" "network" "pulseaudio" "custom/power" ];

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
        format = "<span size=\"large\">󰚥</span> {capacity}%";
        format-charging = "<span size=\"large\">󱐋</span> {capacity}%";
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
        format-wifi = "<span size=\"large\">{icon}</span> {signalStrength}% <span color=\"#ffffff\" size=\"xx-large\">↑</span><span color=\"#8c8c8c\">{bandwidthUpBits}</span> <span color=\"#ffffff\" size=\"xx-large\">↓</span><span color=\"#8c8c8c\">{bandwidthDownBits}</span>";
        format-disconnected = "<span size=\"large\">󰤭</span>";
        format-icons = [ "󰤟" "󰤢" "󰤥" "󰤨" ];
        tooltip-format-wifi = "{essid}";
        tooltip-format-disconnected = "disconnected";
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
        format = "<span size=\"large\">󰕾</span> {volume}%";
        format-muted = "<span size=\"large\">󰝟</span> {volume}%";
        tooltip = false;
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
        background: rgba(10, 10, 15, 0.5);
        border-radius: 16px;
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
