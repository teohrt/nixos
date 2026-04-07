{ spicetify-nix, pkgs, ... }:

{
  imports = [ spicetify-nix.homeManagerModules.default ];

  programs.spicetify = {
    enable = true;
    # brotli is an undeclared runtime dep of newer Spotify versions;
    # adding it here ensures spicetify-nix's wrapper includes it in LD_LIBRARY_PATH
    spotifyPackage = pkgs.spotify.overrideAttrs (old: {
      buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.brotli ];
    });
  };
  # stylix.targets.spicetify handles the theme automatically
}
