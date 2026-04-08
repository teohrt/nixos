{ pkgs, ... }:
{
  # Audio fixes for Framework 16
  environment.systemPackages = [ pkgs.alsa-utils pkgs.pulseaudio ];
  hardware.firmware = [ pkgs.sof-firmware ];
  services.pipewire.audio.enable = true;

  # Set Speaker profile as default (instead of Headphones)
  # Wireplumber config to prefer speaker profile
  services.pipewire.wireplumber.extraConfig."50-framework-speaker" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          { "device.name" = "alsa_card.pci-0000_c2_00.6"; }
        ];
        actions = {
          update-props = {
            "api.acp.auto-profile" = false;
            "device.profile" = "HiFi (Mic1, Mic2, Speaker)";
          };
        };
      }
    ];
  };

  # Fallback: systemd service to set speaker profile after wireplumber starts
  systemd.user.services.framework-audio-fix = {
    description = "Set Framework 16 audio to Speaker profile";
    wantedBy = [ "wireplumber.service" ];
    after = [ "wireplumber.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
      ExecStart = pkgs.writeShellScript "set-speaker-profile" ''
        # Find the Ryzen HD Audio Controller device ID and set Speaker profile (index 2)
        DEVICE_ID=$(${pkgs.wireplumber}/bin/wpctl status 2>/dev/null | \
          ${pkgs.gnugrep}/bin/grep "Ryzen HD Audio Controller" | \
          ${pkgs.gnugrep}/bin/grep "\[alsa\]" | \
          ${pkgs.gnused}/bin/sed 's/.*[^0-9]\([0-9]\+\)\..*/\1/')
        if [ -n "$DEVICE_ID" ]; then
          ${pkgs.wireplumber}/bin/wpctl set-profile "$DEVICE_ID" 2
        fi
        # Also set the default sink via pactl
        ${pkgs.pulseaudio}/bin/pactl set-default-sink alsa_output.pci-0000_c2_00.6.HiFi__Speaker__sink
      '';
    };
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
