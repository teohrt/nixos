{ lib, pkgs, ... }:

{
  specialisation = {
    gruvbox.configuration = {
      # mkForce overrides the base values set in stylix.nix.
      # Explicit base16Scheme is set so the palette is predictable and visually distinct
      # from Nord regardless of what the image auto-generates.
      stylix.image = lib.mkForce ../../../assets/gruvbox/mist_forest.png;
      stylix.base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
    };
    eris.configuration = {
      # No static eris wallpaper yet — reuse a placeholder image so stylix's required
      # field is satisfied. Colors come from the explicit base16Scheme, not the image.
      stylix.image = lib.mkForce ../../../assets/nord/mountain.png;
      stylix.base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/eris.yaml";
    };
  };

  # Allow the user to activate specialisations without a password prompt.
  # /nix/var/nix/profiles/system always points to the base system, so these paths
  # are stable and safe to allowlist regardless of which specialisation is active.
  security.sudo.extraRules = [{
    users = [ "trace" ];
    commands = [
      {
        # /nix/var/nix/profiles/system always points to the base system (no specialisation),
        # even when a specialisation is currently active and /run/current-system points elsewhere.
        command = "/nix/var/nix/profiles/system/bin/switch-to-configuration switch";
        options = [ "NOPASSWD" ];
      }
      {
        command = "/nix/var/nix/profiles/system/specialisation/gruvbox/bin/switch-to-configuration switch";
        options = [ "NOPASSWD" ];
      }
      {
        command = "/nix/var/nix/profiles/system/specialisation/eris/bin/switch-to-configuration switch";
        options = [ "NOPASSWD" ];
      }

    ];
  }];
}
