{ pkgs, ... }:
{
  # Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Login manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sddm-astronaut-theme";
    extraPackages = with pkgs; [ sddm-astronaut kdePackages.qtmultimedia ];
  };
  environment.systemPackages = [ pkgs.sddm-astronaut ];

  # XDG portal for Hyprland
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-hyprland ];
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
    };
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true; # enables network printer discovery on the local network
  };

  security.pam.services.hyprlock = {};

  # Required for Nautilus: trash, removable media, MTP, network shares
  services.gvfs.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
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

  services.upower.enable = true;
}
