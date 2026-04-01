{ spicetify-nix, ... }:

{
  imports = [ spicetify-nix.homeManagerModules.default ];

  programs.spicetify.enable = true;
  # stylix.targets.spicetify handles the theme automatically
}
