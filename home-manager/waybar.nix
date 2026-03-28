{ pkgs, ... }:

let
  powerMenu = pkgs.writeShellScript "waybar-power-menu" ''
    CHOICE=$(printf "  Shutdown\n  Restart\n  Lock\n  Suspend\n  Log Out" \
      | ${pkgs.rofi}/bin/rofi -dmenu -p "" \
          -theme-str 'window { width: 200px; } listview { lines: 5; }')
    case "$CHOICE" in
      *Shutdown) systemctl poweroff ;;
      *Restart)  systemctl reboot ;;
      *Lock)     loginctl lock-session ;;
      *Suspend)  systemctl suspend ;;
      *"Log Out") hyprctl dispatch exit ;;
    esac
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
      margin-top = 8;
      margin-left = 16;
      margin-right = 16;
      spacing = 8;

      modules-left = [ "custom/launcher" "clock" "custom/weather" ];
      modules-center = [ "hyprland/workspaces" ];
      modules-right = [ "cpu" "memory" "network" "bluetooth" "pulseaudio" "battery" "custom/power" ];

      "custom/launcher" = {
        format = "󱄅";
        on-click = "pkill -x rofi || rofi -show drun";
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

      cpu = {
        format = "󰘚 {usage}%";
        interval = 2;
        tooltip-format = "CPU\n{usage}%  Load: {load}";
      };

      memory = {
        format = "󰻠 {percentage}%";
        interval = 2;
        tooltip-format = "RAM\n{percentage}%  {used:0.1f}GB / {total:0.1f}GB\nAvail: {avail:0.1f}GB";
      };

      network = {
        format-wifi = "󰤨";
        format-disconnected = "󰤭";
        tooltip-format-wifi = "{essid}  {signalStrength}%\n↑ {bandwidthUpBits}  ↓ {bandwidthDownBits}";
        tooltip-format-disconnected = "disconnected";
        on-click = "rfkill unblock wifi && alacritty --title wifi -e impala";
      };

      bluetooth = {
        format = "󰂯";
        format-connected = "󰂱";
        format-disabled = "󰂲";
        tooltip-format = "{controller_alias}\n{num_connections} connected";
        tooltip-format-connected = "{controller_alias}\n{num_connections} connected\n{device_enumerate}";
        tooltip-format-enumerate-connected = "  {device_alias}";
        on-click = "blueman-manager";
      };

      pulseaudio = {
        format = "󰕾";
        format-muted = "󰝟";
        tooltip-format = "{volume}%: {desc}";
        on-click = "pavucontrol";
      };

      "custom/power" = {
        format = "⏻";
        on-click = "${powerMenu}";
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
      #cpu:hover,
      #memory:hover,
      #custom-weather:hover,
      #custom-power:hover {
        background: rgba(126, 186, 228, 0.15);
      }

      #workspaces {
        background: rgba(10, 10, 15, 0.85);
        border-radius: 12px;
        padding: 0 4px;
      }

      #workspaces button {
        padding: 0 4px;
        color: rgba(255, 255, 255, 0.3);
        box-shadow: none;
      }

      #workspaces button.active {
        color: #ffffff;
      }

      #workspaces:hover {
        background: rgba(126, 186, 228, 0.15);
      }

      #workspaces button:hover {
        background: transparent;
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
      #cpu,
      #memory,
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
