{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./system-apps.nix
  ];
  
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "my-nixos";

  # Disable WiFi 6 (802.11ax) parsing in the iwlwifi driver — iwd fails to
  # parse HE capabilities on this adapter (Intel 8265/8275), causing connect-failed
  boot.extraModprobeConfig = "options iwlwifi disable_11ax=1";

  # iwd manages wifi (required by the impala TUI — impala talks directly to iwd
  # over D-Bus and cannot coexist with NetworkManager)
  networking.wireless.iwd.enable = true;
  networking.wireless.iwd.settings = {
    General = {
      EnableNetworkConfiguration = true;  # iwd handles DHCP for wifi
    };
    Settings.AutoConnect = true;
  };

  # systemd-networkd handles wired ethernet, systemd-resolved handles DNS
  networking.useNetworkd = true;
  networking.useDHCP = false;
  services.resolved.enable = true;
  systemd.network.networks."10-wired" = {
    matchConfig.Name = "en*";
    networkConfig.DHCP = "yes";
  };
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  programs.git.prompt.enable = true;

  # Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Login manager — minimal black screen with password input, auto-selects hyprland session
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "where_is_my_sddm_theme";
    extraPackages = with pkgs; [ kdePackages.qt5compat ];
  };
  environment.systemPackages = [
    (pkgs.where-is-my-sddm-theme.override {
      themeConfig.General = {
        backgroundFill = "#000000";
        basicTextColor = "#ECEFF4";
        passwordCursorColor = "#88C0D0";
        passwordTextColor = "#ECEFF4";
        passwordInputBackground = "#3B4252";
        passwordInputRadius = "10";
        font = "JetBrains Mono";
        passwordCharacter = "•";
        passwordFontSize = "24";
        showUsersByDefault = "false";
        showSessionsByDefault = "false";
      };
    })
  ];

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
  security.pam.services.hyprlock = {};

  # Required for Thunar: trash, removable media, MTP, network shares
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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.trace = {
    isNormalUser = true;
    description = "trace";
    extraGroups = [ "wheel" "video" ]; # video group allows brightnessctl without sudo
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
