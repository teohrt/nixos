{ lib, pkgs, ... }:

{
  specialisation = {
    gruvbox.configuration = {
      # mkForce overrides the base values set in stylix.nix.
      # Explicit base16Scheme is set so the palette is predictable and visually distinct
      # from Nord regardless of what the image auto-generates.
      stylix.image = lib.mkForce ../assets/gruvbox/mist_forest.png;
      stylix.base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
    };
    eris.configuration = {
      # No static eris wallpaper yet — reuse a placeholder image so stylix's required
      # field is satisfied. Colors come from the explicit base16Scheme, not the image.
      stylix.image = lib.mkForce ../assets/nord/mountain.png;
      stylix.base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/eris.yaml";
    };
  };

  # Allow the user to activate specialisations without a password prompt.
  # The stable /run/current-system symlink means these paths are safe to allowlist.
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
        command = "/run/current-system/specialisation/gruvbox/bin/switch-to-configuration switch";
        options = [ "NOPASSWD" ];
      }
      {
        command = "/run/current-system/specialisation/eris/bin/switch-to-configuration switch";
        options = [ "NOPASSWD" ];
      }
      {
        # Force home-manager to re-run after switching between specialisations.
        # home-manager-trace.service is oneshot/RemainAfterExit, so switch-to-configuration
        # won't restart it if already active — restart explicitly to rewrite config files.
        command = "/run/current-system/sw/bin/systemctl restart home-manager-trace.service";
        options = [ "NOPASSWD" ];
      }
    ];
  }];
}
