{ pkgs, ... }:
{
  imports = [
    ./hardware.nix
  ];

  networking.hostName = "my-thinkpad";

  hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];

  # Intel 8265 WiFi adapter advertises WiFi 6 (802.11ax) HE capabilities but
  # can't parse them correctly, causing connection failures. Disabling 11ax
  # forces a fallback to WiFi 5 (802.11ac). Framework 16 doesn't need this.
  boot.extraModprobeConfig = "options iwlwifi disable_11ax=1";

  system.stateVersion = "25.11";
}
