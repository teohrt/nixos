{ pkgs, ... }: {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    plugins = [
      (pkgs.rofi-calc.override { rofi-unwrapped = pkgs.rofi-unwrapped; })
    ];
    extraConfig = {
      modi = "drun,window,calc";
      show-icons = true;
      drun-display-format = "{icon} {name}";
      disable-history = false;
    };
  };
}
