{ lib, ... }:

{
  specialisation = {
    everforest.configuration = {
      # mkForce overrides the base stylix.image set in stylix.nix
      stylix.image = lib.mkForce ../assets/everforest/mist_forest.png;
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
