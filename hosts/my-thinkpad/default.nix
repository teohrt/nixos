{ pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ../../modules/nixos/core
    ../../modules/nixos/optional/desktop.nix
    ../../modules/nixos/optional/networking.nix
    ../../modules/nixos/optional/docker.nix
    ../../modules/nixos/optional/stylix.nix
    ../../modules/nixos/optional/themes.nix
    ../../modules/nixos/optional/system-apps.nix
  ];

  networking.hostName = "my-thinkpad";

  # Disable WiFi 6 (802.11ax) parsing in the iwlwifi driver — iwd fails to
  # parse HE capabilities on this adapter (Intel 8265/8275), causing connect-failed
  boot.extraModprobeConfig = "options iwlwifi disable_11ax=1";

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # Allow jolt to read CPU power metrics from the Intel RAPL interface
  services.udev.extraRules = ''
    SUBSYSTEM=="powercap", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod o+r /sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj /sys/class/powercap/intel-rapl/intel-rapl:0/*/energy_uj"
  '';

  home-manager.users.trace = {
    imports = [
      ../../modules/home/core
      ../../modules/home/optional/user-apps.nix
      ../../modules/home/optional/desktop/hyprland.nix
      ../../modules/home/optional/desktop/waybar.nix
      ../../modules/home/optional/desktop/walker.nix
      ../../modules/home/optional/desktop/wallpaper.nix
      ../../modules/home/optional/desktop/hyprlock.nix
      ../../modules/home/optional/desktop/hypridle.nix
      ../../modules/home/optional/apps/git.nix
      ../../modules/home/optional/apps/alacritty.nix
      ../../modules/home/optional/apps/firefox.nix
      ../../modules/home/optional/apps/vscode.nix
      ../../modules/home/optional/apps/obsidian.nix
      ../../modules/home/optional/apps/spicetify.nix
    ];
  };

  system.stateVersion = "25.11";
}
