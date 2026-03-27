{ pkgs, ... }: {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    extraConfig = {
      modi = "drun,window,calc:${pkgs.rofi-calc}/lib/rofi/calc.so";
      show-icons = true;
      drun-display-format = "{icon} {name}";
      disable-history = false;
    };
  };
}
