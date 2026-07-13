# Desktop environment: Hyprland compositor, greetd login, PipeWire audio, Bluetooth, printing.
{
  pkgs,
  username,
  ...
}:
let
  hyprctl = "${pkgs.hyprland}/bin/hyprctl";

  greeterInit = pkgs.writeShellScript "greeter-init" ''
    log=/var/log/regreet/greeter-monitors.log

    # Log what the greeter's Hyprland sees
    echo "=== initial ===" > "$log"
    ${hyprctl} monitors >> "$log" 2>&1

    # If lid is closed, disable the laptop panel
    if grep -q closed /proc/acpi/button/lid/LID0/state 2>/dev/null; then
      echo "=== lid closed, disabling eDP-1 ===" >> "$log"
      ${hyprctl} keyword monitor eDP-1,disable >> "$log" 2>&1
    fi

    echo "=== after lid check ===" >> "$log"
    ${hyprctl} monitors >> "$log" 2>&1

    # Seed regreet state on first run
    mkdir -p /var/lib/regreet
    test -f /var/lib/regreet/state.toml || \
      printf 'last_user = "${username}"\n\n[user_to_last_sess]\n${username} = "Hyprland (uwsm-managed)"\n' \
        > /var/lib/regreet/state.toml

    ${pkgs.regreet}/bin/regreet
    ${hyprctl} dispatch exit
  '';

  greeterConfig = pkgs.writeText "greetd-hyprland.conf" ''
    # External monitors: normal setup
    monitor = , preferred, auto, 1

    # Laptop display mirrors the external monitor when both are connected;
    # falls back to standalone when undocked (mirror target absent)
    monitor = eDP-1, preferred, auto, 1, mirror, DP-1

    misc {
      disable_hyprland_logo = true
      disable_splash_rendering = true
      disable_hyprland_guiutils_check = true
      force_default_wallpaper = 0
    }

    animations {
      enabled = false
    }

    exec-once = ${greeterInit}
  '';
in
{
  # Hyprland Wayland compositor
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  # regreet greeter — provides config, state dirs, and accounts-daemon
  programs.regreet.enable = true;

  # Login manager — greetd with Hyprland as greeter compositor for multi-monitor support
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.dbus}/bin/dbus-run-session ${pkgs.hyprland}/bin/start-hyprland -- --config ${greeterConfig}";
        user = "greeter";
      };
      initial_session = {
        command = "${pkgs.uwsm}/bin/uwsm start -e -D Hyprland hyprland.desktop";
        user = username;
      };
    };
  };

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

    # Battery status daemon (used by Noctalia bar, hypridle for battery-aware behavior)
    upower.enable = true;

    # Power profile switching (power-saver, balanced, performance)
    # Works with Intel P-state and AMD P-state drivers
    power-profiles-daemon.enable = true;
  };

  # PAM integration for lock screens (allows unlocking with user password)
  # Realtime scheduling for PipeWire (low-latency audio)
  security = {
    pam.services.hyprlock = { };
    pam.services.noctalia = { };
    rtkit.enable = true;
  };
}
