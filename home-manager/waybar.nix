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
      modules-right = [ "cpu" "memory" "pulseaudio" ];

      "hyprland/workspaces" = {
        format = "{id}";
        on-scroll-up = "hyprctl dispatch workspace e+1";
        on-scroll-down = "hyprctl dispatch workspace e-1";
      };

      clock = {
        format = "{:%a %b %d  %I:%M %p}";
        tooltip = false;
      };

      cpu = {
        format = "cpu {usage}%";
        interval = 5;
      };

      memory = {
        format = "mem {percentage}%";
        interval = 5;
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
      }

      window#waybar {
        background: rgba(10, 10, 15, 0.85);
        color: #cdd6f4;
        border-radius: 12px;
      }

      .modules-left,
      .modules-center,
      .modules-right {
        padding: 0 8px;
      }

      #workspaces button {
        padding: 0 8px;
        color: #585b70;
        background: transparent;
        box-shadow: none;
      }

      #workspaces button.active {
        color: #cdd6f4;
      }

      #workspaces button:hover {
        background: rgba(255, 255, 255, 0.05);
        border-radius: 8px;
      }

      #clock {
        color: #cdd6f4;
        font-weight: 500;
      }

      #cpu,
      #memory,
      #pulseaudio {
        color: #6c7086;
        padding: 0 6px;
      }

      #pulseaudio.muted {
        color: #45475a;
      }
    '';
  };
}
