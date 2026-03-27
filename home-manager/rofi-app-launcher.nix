{ pkgs, ... }: {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    plugins = [
      (pkgs.rofi-calc.override { rofi-unwrapped = pkgs.rofi-unwrapped; })
    ];
    extraConfig = {
      modi = "drun,window,calc";
      plugin-path = "${pkgs.rofi-calc}/lib/rofi";
      show-icons = true;
      drun-display-format = "{icon} {name}";
      disable-history = false;
    };
  };
}
