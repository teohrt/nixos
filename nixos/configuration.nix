{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./system-apps.nix
  ];
  
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "my-nixos";
  networking.networkmanager.enable = true;
  # Use iwd as the wifi backend so the impala TUI can manage wifi connections
  networking.networkmanager.wifi.backend = "iwd";
  networking.wireless.iwd.enable = true;
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  programs.git.prompt.enable = true;

  # Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Login manager
  programs.regreet = {
    enable = true;
    settings = {
      background = {
        path = ../assets/wallpaper.png;
        fit = "Cover";
      };
      GTK = {
        application_prefer_dark_theme = lib.mkForce true;
        font_name = lib.mkForce "JetBrains Mono 12";
      };
    };
  };

  # XDG portal for Hyprland
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-hyprland ];
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

  # Enable sound with pipewire.
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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.trace = {
    isNormalUser = true;
    description = "trace";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = [];
  };

  nixpkgs.config.allowUnfree = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
