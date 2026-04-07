{ spicetify-nix, pkgs-spotify, ... }:

{
  imports = [ spicetify-nix.homeManagerModules.default ];

  programs.spicetify = {
    enable = true;
    # pinned to a nixpkgs commit known to work with spicetify-nix;
    # bump nixpkgs-spotify in flake.nix only after confirming compatibility
    spotifyPackage = pkgs-spotify.spotify;
  };
  # stylix.targets.spicetify handles the theme automatically
}
