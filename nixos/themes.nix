{ lib, pkgs, ... }:

{
  specialisation = {
    everforest.configuration = {
      # mkForce overrides the base values set in stylix.nix.
      # Explicit base16Scheme is set so the palette is predictable and visually distinct
      # from Nord regardless of what the image auto-generates.
      stylix.image = lib.mkForce ../assets/everforest/mist_forest.png;
      stylix.base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
    };
  };

  # Allow the user to activate specialisations without a password prompt.
  # The stable /run/current-system symlink means these paths are safe to allowlist.
  security.sudo.extraRules = [{
    users = [ "trace" ];
    commands = [
      {
        command = "/run/current-system/bin/switch-to-configuration switch";
        options = [ "NOPASSWD" ];
      }
      {
        command = "/run/current-system/specialisation/everforest/bin/switch-to-configuration switch";
        options = [ "NOPASSWD" ];
      }
    ];
  }];
}
