{ pkgs, ... }: {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    plugins = [ pkgs.rofi-calc ];
    extraConfig = {
      modi = "drun,window,calc";
      show-icons = true;
      drun-display-format = "{icon} {name}";
      disable-history = false;
    };
  };
}
