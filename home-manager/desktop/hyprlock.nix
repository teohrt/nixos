{ ... }:

{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        grace = 0;
      };

      background = [{
        monitor = "";
        color = "rgb(0, 0, 0)";
      }];

      input-field = [{
        monitor = "";
        size = "400, 50";
        position = "0, -100";
        halign = "center";
        valign = "center";
      }];


      label = [
        # Clock
        {
          monitor = "";
          text = ''cmd[update:1000] echo "$(date +"%H:%M")"'';
          color = "rgba(236, 239, 244, 1.0)";
          font_size = 90;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 160";
          halign = "center";
          valign = "center";
        }
        # Date
        {
          monitor = "";
          text = ''cmd[update:1000] echo "$(date +"%A, %B %d")"'';
          color = "rgba(236, 239, 244, 0.8)";
          font_size = 18;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 60";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
