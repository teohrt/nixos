{ pkgs, ... }: {
  stylix = {
    enable = true;
    image = ../assets/wallpaper.png;
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";

    opacity = {
      terminal     = 0.85;
      applications = 0.90;
      popups       = 0.85;
      desktop      = 1.0;
    };
  };
}
