{ pkgs, lib, ... }:
{
  # Zoom runs on XWayland — wrap it to self-scale so clicks align with force_zero_scaling
  nixpkgs.overlays = [
    (_: prev: {
      zoom-us = prev.zoom-us.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          wrapProgram $out/bin/zoom --set QT_SCALE_FACTOR 1.25
        '';
      });
    })
  ];
  # Audio fixes for Framework 16
  # The AMD Ryzen audio hardware (ALC285 codec + SOF firmware) is newer and has quirks:
  # - WirePlumber auto-selects the wrong profile (Headphones instead of Speaker)
  # - Requires explicit profile forcing and a fallback systemd service
  # ThinkPads with mature Intel audio don't need any of this.
  environment.systemPackages = [ pkgs.alsa-utils pkgs.pulseaudio ];
  hardware.firmware = [ pkgs.sof-firmware ];
  services.pipewire.audio.enable = true;

  # Force Speaker profile (WirePlumber defaults to Headphones otherwise)
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

  # Auto-switch to Bluetooth headphones when connected
  services.pipewire.wireplumber.extraConfig."51-bluetooth-priority" = {
    "monitor.bluez.rules" = [
      {
        matches = [
          { "device.name" = "~bluez_card.*"; }
        ];
        actions = {
          update-props = {
            "bluez5.auto-connect" = [ "a2dp_sink" "hfp_hf" ];
          };
        };
      }
      {
        matches = [
          { "node.name" = "~bluez_output.*"; }
        ];
        actions = {
          update-props = {
            "priority.driver" = 3000;
            "priority.session" = 3000;
          };
        };
      }
    ];
  };

  # Auto-switch to Bluetooth audio when device connects
  systemd.user.services.bluetooth-autoswitch = {
    description = "Switch audio to Bluetooth when connected";
    wantedBy = [ "pipewire.service" ];
    after = [ "pipewire.service" "wireplumber.service" ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 5;
      ExecStart = pkgs.writeShellScript "bluetooth-autoswitch" ''
        ${pkgs.pulseaudio}/bin/pactl subscribe | while read -r line; do
          if echo "$line" | ${pkgs.gnugrep}/bin/grep -q "Event 'new' on sink"; then
            sleep 1
            # Get the Bluetooth sink name if one exists
            BT_SINK=$(${pkgs.pulseaudio}/bin/pactl list short sinks | \
              ${pkgs.gnugrep}/bin/grep -i "bluez" | \
              ${pkgs.coreutils}/bin/head -1 | \
              ${pkgs.coreutils}/bin/cut -f2)
            if [ -n "$BT_SINK" ]; then
              ${pkgs.pulseaudio}/bin/pactl set-default-sink "$BT_SINK"
            fi
          fi
        done
      '';
    };
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
    ../../modules/nixos/optional/system-apps.nix
    ../../modules/nixos/optional/sops.nix
    ../../modules/nixos/optional/steam.nix
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
      ../../modules/home/optional/apps/kitty.nix
      ../../modules/home/optional/apps/firefox.nix
      ../../modules/home/optional/apps/vscode.nix
      ../../modules/home/optional/apps/obsidian.nix
      ../../modules/home/optional/apps/spicetify.nix
      ../../modules/home/optional/ssh.nix
    ];

    # Framework 16 specific: 1.25x scale (overrides shared 1.2x)
    wayland.windowManager.hyprland.settings.monitor = lib.mkForce ",preferred,auto,1.25";

    # Framework 16 specific: reduced mouse sensitivity
    wayland.windowManager.hyprland.settings.input = {
      sensitivity = lib.mkForce (-0.25); # range -1.0 to 1.0, negative = slower
      # accel_profile defaults to "adaptive" (acceleration enabled)
    };

    # Lid switch handling: disable laptop display and backlight when closed.
    # Hardware-specific: uses amdgpu_bl1 backlight device and 1.2x scale for Framework 16.
    # Other laptops would need different backlight device (e.g. intel_backlight) and scale.
    wayland.windowManager.hyprland.settings.bindl = [
      ", switch:on:Lid Switch, exec, hyprctl keyword monitor 'eDP-1,disable' && brightnessctl -d amdgpu_bl1 set 0"
      ", switch:off:Lid Switch, exec, hyprctl keyword monitor 'eDP-1,preferred,auto,1.2' && brightnessctl -d amdgpu_bl1 set 100%"
    ];

  };

  system.stateVersion = "25.11";
}
