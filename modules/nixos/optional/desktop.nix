# Desktop environment: Hyprland compositor, SDDM login, PipeWire audio, Bluetooth, printing.
{
  pkgs,
  pkgs-hyprland,
  username,
  ...
}:
{
  # Hyprland Wayland compositor (pinned nixpkgs for 0.55.4 with Lua config support)
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = pkgs-hyprland.hyprland;
    portalPackage = pkgs-hyprland.xdg-desktop-portal-hyprland;
  };

  # Login manager
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
      theme = "sddm-astronaut-theme";
      extraPackages = with pkgs; [
        sddm-astronaut
        kdePackages.qtmultimedia
      ];
    };
    autoLogin = {
      enable = true;
      user = username;
    };
  };
  environment.systemPackages = [ pkgs.sddm-astronaut ];

  # XDG portal for Hyprland
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
    # explicitly route screensharing/remotedesktop to hyprland portal, everything else to gtk
    config.common = {
      "org.freedesktop.impl.portal.ScreenCast" = "hyprland";
      "org.freedesktop.impl.portal.RemoteDesktop" = "hyprland";
      default = [ "gtk" ];
    };
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings = {
    General = {
      # Enables AAC codec negotiation, battery reporting, and other modern features
      Experimental = true;
      # Disable auto-pairing - require explicit pairing via TUI
      JustWorksRepairing = "never";
    };
    Policy = {
      AutoEnable = false;
    };
  };

  # Enable CUPS to print documents.
  services = {
    printing.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true; # enables network printer discovery on the local network
    };

    # Required for Nautilus: trash, removable media, MTP, network shares
    gvfs.enable = true;

    # PipeWire audio
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.configPackages = [
        (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/51-airpods.conf" ''
          monitor.bluez.properties = {
            # AAC codec for high-quality audio (AirPods' preferred codec)
            bluez5.codecs = [ aac sbc sbc_xq ]
            # mSBC enables wideband audio on the mic (HFP), improving mic quality
            bluez5.enable-msbc = true
            bluez5.enable-hw-volume = true
            # Enable all headset roles so mic and audio both work
            bluez5.headset-roles = [ hsp_hs hsp_ag hfp_hf hfp_ag ]
          }
        '')
      ];
    };

    # Battery status daemon (used by noctalia-shell bar, hypridle for battery-aware behavior)
    upower.enable = true;

    # Power profile switching (power-saver, balanced, performance)
    # Works with Intel P-state and AMD P-state drivers
    power-profiles-daemon.enable = true;
  };

  # PAM integration for lock screens (allows unlocking with user password)
  # Realtime scheduling for PipeWire (low-latency audio)
  security = {
    pam.services.hyprlock = { };
    pam.services.noctalia-shell = { };
    rtkit.enable = true;
  };
}
