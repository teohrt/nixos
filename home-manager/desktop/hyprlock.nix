{ lib, ... }:

{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        grace = 0;
      };

      # Override Stylix's wallpaper background with solid black.
      background = lib.mkForce [{
        monitor = "";
        color = "rgb(0, 0, 0)";
      }];

    };
  };
}
