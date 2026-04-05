{ lib, ... }:

{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        grace = 0;
      };

      label = [{
        monitor = "";
        text = "locked";
        font_size = 24;
        position = "0, 100";
        halign = "center";
        valign = "center";
      }];

      # Override Stylix's wallpaper background with solid black.
      background = lib.mkForce [{
        monitor = "";
        color = "rgb(0, 0, 0)";
      }];

    };
  };
}
