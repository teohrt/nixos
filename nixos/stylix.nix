{ pkgs, ... }:
let
  bibata = pkgs.bibata-cursors;
in {
  stylix = {
    enable = true;
    image = ../assets/wallpaper.png;
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";

    cursor = {
      package = bibata;
      name = "Bibata-Modern-Ice";
      size = 24;
    };

    opacity = {
      terminal     = 0.6;
      applications = 0.8;
      popups       = 0.7;
      desktop      = 1.0;
    };
  };
}
