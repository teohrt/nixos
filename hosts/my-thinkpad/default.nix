{ lib, username, ... }:
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

  # Intel 8265 WiFi adapter advertises WiFi 6 (802.11ax) HE capabilities but
  # can't parse them correctly, causing connection failures. Disabling 11ax
  # forces a fallback to WiFi 5 (802.11ac). Framework 16 doesn't need this.
  boot.extraModprobeConfig = "options iwlwifi disable_11ax=1";

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  home-manager.users.${username} = {
    wayland.windowManager.hyprland.settings.monitor = lib.mkForce ",preferred,auto,1";
  };

  system.stateVersion = "25.11";
}
