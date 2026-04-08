# Theme definitions and home-manager configuration builder
# Used by flake.nix to generate homeConfigurations for each theme
{ pkgs }:

{
  # Available themes - add new themes here
  themes = {
    nord = {
      image = ../../assets/nord/mountain.png;
      scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
    };
    gruvbox = {
      image = ../../assets/gruvbox/mist_forest.png;
      scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
    };
    eris = {
      image = ../../assets/nord/mountain.png; # placeholder
      scheme = "${pkgs.base16-schemes}/share/themes/eris.yaml";
    };
  };

  # Shared Stylix settings applied to all themes
  stylixBase = {
    enable = true;
    polarity = "dark";
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
