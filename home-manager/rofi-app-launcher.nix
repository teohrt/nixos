{ pkgs, ... }: {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    extraConfig = {
      modi = "drun,window";
      show-icons = true;
      drun-display-format = "{icon} {name}";
      disable-history = false;
    };
  };
}
