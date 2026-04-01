{ pkgs, ... }: {
  stylix = {
    enable = true;
    image = ../assets/wallpaper.png;
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";

    opacity = {
      terminal     = 0.6;
      applications = 0.8;
      popups       = 0.7;
      desktop      = 1.0;
    };
  };
}
