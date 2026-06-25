{
  lib,
  username,
  baseHomeModules,
  ...
}:
{
  imports = [
    ./hardware.nix
    ../../modules/nixos/core
    ../../modules/nixos/optional/desktop.nix
    ../../modules/nixos/optional/networking.nix
    ../../modules/nixos/optional/docker.nix
    ../../modules/nixos/optional/system-apps.nix
    ../../modules/nixos/optional/sops.nix
    ../../modules/nixos/optional/steam.nix
  ];

  networking.hostName = "my-thinkpad";

  # Disable WiFi 6 (802.11ax) parsing in the iwlwifi driver — iwd fails to
  # parse HE capabilities on this adapter (Intel 8265/8275), causing connect-failed
  boot.extraModprobeConfig = "options iwlwifi disable_11ax=1";

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  home-manager.users.${username} = {
    imports = baseHomeModules;

    wayland.windowManager.hyprland.settings.monitor = lib.mkForce ",preferred,auto,1";
  };

  system.stateVersion = "25.11";
}
