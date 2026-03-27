{ pkgs, ... }:

let
  weatherScript = pkgs.writeShellScript "waybar-weather" ''
    WEATHER=$(${pkgs.curl}/bin/curl -sf "wttr.in/?format=j1")
    if [ -z "$WEATHER" ]; then
      echo '{"text": "󰖑 --", "tooltip": "Weather unavailable"}'
      exit
    fi

    CODE=$(echo "$WEATHER" | ${pkgs.jq}/bin/jq -r '.current_condition[0].weatherCode')
    TEMP=$(echo "$WEATHER" | ${pkgs.jq}/bin/jq -r '.current_condition[0].temp_F')
    FEELS=$(echo "$WEATHER" | ${pkgs.jq}/bin/jq -r '.current_condition[0].FeelsLikeF')
    HUMIDITY=$(echo "$WEATHER" | ${pkgs.jq}/bin/jq -r '.current_condition[0].humidity')
    DESC=$(echo "$WEATHER" | ${pkgs.jq}/bin/jq -r '.current_condition[0].weatherDesc[0].value')
    WIND=$(echo "$WEATHER" | ${pkgs.jq}/bin/jq -r '.current_condition[0].windspeedMiles')

    case $CODE in
      113)                   ICON="󰖙" ;;  # Clear/Sunny
      116)                   ICON="󰖕" ;;  # Partly cloudy
      119|122)               ICON="󰖐" ;;  # Cloudy/Overcast
      143|248|260)           ICON="󰖑" ;;  # Mist/Fog
      200|386|389|392|395)   ICON="󰖓" ;;  # Thunder
      263|266|281|293|296|299|302|305|308|311|314|317|350|353|356|359|362|365|374|377) ICON="󰖗" ;;  # Rain
      179|182|185|227|230|323|326|329|332|335|338|368|371) ICON="󰖘" ;;  # Snow/Sleet
      *)                     ICON="󰖐" ;;
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
        padding: 0 12px;
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
        padding: 0 12px;
      }

      #pulseaudio.muted {
        color: rgba(255, 255, 255, 0.3);
      }
    '';
  };
}
