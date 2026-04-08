{ pkgs, ... }:
{
  # Audio fixes for Framework 16
  environment.systemPackages = [ pkgs.alsa-utils pkgs.pulseaudio ];
  hardware.firmware = [ pkgs.sof-firmware ];
  services.pipewire.audio.enable = true;

  # Set Speaker profile as default (instead of Headphones)
  services.pipewire.wireplumber.extraConfig."50-framework-speaker" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          { "device.name" = "alsa_card.pci-0000_c2_00.6"; }
        ];
        actions = {
          update-props = {
            "device.profile" = "HiFi (Mic1, Mic2, Speaker)";
          };
        };
      }
      {
        matches = [
          { "node.name" = "~alsa_output.pci-0000_c2_00.6.*Speaker*"; }
        ];
        actions = {
          update-props = {
            "priority.driver" = 2000;
            "priority.session" = 2000;
          };
        };
      }
    ];
  };
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

  networking.hostName = "framework-16";

  # Firmware for audio, wifi, etc.
  hardware.enableRedistributableFirmware = true;


  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

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
      ../../modules/home/optional/apps/alacritty.nix
      ../../modules/home/optional/apps/firefox.nix
      ../../modules/home/optional/apps/vscode.nix
      ../../modules/home/optional/apps/obsidian.nix
      ../../modules/home/optional/apps/spicetify.nix
    ];
  };

  system.stateVersion = "25.11";
}
