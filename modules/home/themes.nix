# Stylix theme configuration (Nord)
# Colors come from the base16 scheme, not the image.
# The image is a required placeholder for stylix.
{ pkgs }:

let
  # Placeholder image for stylix (required attribute, but colors come from scheme)
  placeholderImage = pkgs.fetchurl {
    url = "https://w.wallhaven.cc/full/8x/wallhaven-8x225j.jpg";
    sha256 = "06q04fivqws6smn3plmyslf8s9xdykhrx3sa09vjnywrh5wjk3fq";
  };
in
{
  stylix = {
    enable = true;
    polarity = "dark";
    image = placeholderImage;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";

    fonts.monospace = {
      package = pkgs.nerd-fonts.jetbrains-mono;
      name = "JetBrainsMono Nerd Font Mono";
    };

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };

    opacity = {
      terminal = 0.7;
      applications = 0.8;
      popups = 0.8;
      desktop = 1.0;
    };
  };
}
