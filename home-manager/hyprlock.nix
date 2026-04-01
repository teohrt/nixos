{ ... }:

{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        grace = 0;
      };

      input-field = [
        {
          monitor = "";
          size = "300, 50";
          position = "0, -80";
          halign = "center";
          valign = "center";
          outline_thickness = 2;
          dots_size = 0.2;
          dots_spacing = 0.15;
          dots_center = true;
          outer_color = "rgb(136, 192, 208)";   # Nord blue #88C0D0
          inner_color = "rgb(59, 66, 82)";       # Nord dark #3B4252
          font_color = "rgb(236, 239, 244)";     # Nord light #ECEFF4
          fade_on_empty = true;
          placeholder_text = "";
          check_color = "rgb(163, 190, 140)";    # Nord green
          fail_color = "rgb(191, 97, 106)";      # Nord red
          fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
        }
      ];

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
