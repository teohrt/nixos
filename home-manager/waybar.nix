{ pkgs, ... }:

let
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

      modules-left = [ "custom/launcher" "hyprland/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [ "custom/weather" "battery" "network" "pulseaudio" ];

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

      network = {
        format-wifi = "󰤨";
        format-disconnected = "󰤭";
        tooltip-format-wifi = "{essid}  {signalStrength}%";
        tooltip-format-disconnected = "disconnected";
        on-click = "nm-connection-editor";
      };

      pulseaudio = {
        format = "󰕾 {volume}%";
        format-muted = "󰝟";
        on-click = "pavucontrol";
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
        padding: 4px 12px;
        font-size: 16px;
      }

      #custom-launcher:hover {
        background: rgba(126, 186, 228, 0.15);
      }

      #workspaces {
        background: rgba(10, 10, 15, 0.85);
        border-radius: 12px;
        padding: 0 4px;
      }

      #workspaces button {
        padding: 0 8px;
        color: rgba(255, 255, 255, 0.3);
        box-shadow: none;
      }

      #workspaces button.active {
        color: #ffffff;
      }

      #workspaces button:hover {
        background: rgba(255, 255, 255, 0.05);
        border-radius: 8px;
      }

      #clock,
      #battery,
      #network,
      #pulseaudio,
      #custom-weather {
        background: rgba(10, 10, 15, 0.85);
        border-radius: 12px;
        padding: 4px 12px;
      }

      #pulseaudio.muted {
        color: rgba(255, 255, 255, 0.3);
      }
    '';
  };
}
