{ ... }: {
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

      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [ "battery" "network" "pulseaudio" ];

      "hyprland/workspaces" = {
        format = "{id}";
        on-scroll-up = "hyprctl dispatch workspace e+1";
        on-scroll-down = "hyprctl dispatch workspace e-1";
      };

      clock = {
        format = "{:%I:%M %p}";
        tooltip = false;
      };

      battery = {
        format = "bat {capacity}%";
        format-charging = "bat {capacity}% +";
        interval = 30;
      };

      network = {
        format-wifi = "󰤨";
        format-disconnected = "󰤭";
        tooltip-format-wifi = "{essid}  {signalStrength}%";
        tooltip-format-disconnected = "disconnected";
        on-click = "kitty -e nmtui";
      };

      pulseaudio = {
        format = "vol {volume}%";
        format-muted = "muted";
        on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
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
      #pulseaudio {
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
