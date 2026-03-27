{ pkgs, ... }: {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    plugins = [
      (pkgs.rofi-calc.override { rofi-unwrapped = pkgs.rofi-unwrapped; })
    ];
    extraConfig = {
      modi = "combi,window,calc";
      combi-modi = "drun,calc";
      show-icons = true;
      drun-display-format = "{icon} {name}";
      disable-history = false;
      calc-qalc-binary = "${pkgs.qalculate-gtk}/bin/qalc";
      calc-hint-result = "= ";
      calc-hint-welcome = "Calc";
    };
  };
}
