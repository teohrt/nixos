# Network privacy: randomize MAC addresses and DHCP hostnames on each boot,
# and suppress protocols that broadcast the real hostname.
#
# What this covers:
#   - MAC address:    randomized per-connection by NetworkManager
#   - DHCP hostname:  spoofed per-boot via a systemd service that patches
#                     NM connection files before NM starts (IPv4 only —
#                     NM's DHCPv6 client doesn't send a hostname by default)
#   - LLMNR:          disabled so systemd-resolved won't answer link-local
#                     multicast queries with the real hostname
#   - DHCPv6 DUID:    set to link-layer mode so the DUID is derived from
#                     the (randomized) MAC instead of a stable UUID
#   - mDNS (Avahi):   publishing disabled so the real hostname isn't
#                     broadcast as "hostname.local" — service discovery
#                     (e.g. network printers) still works
#
# The system hostname (networking.hostName) is never changed — it stays
# available locally for the shell prompt, logs, and nixos-rebuild.
#
# Hostnames are generated to look like common consumer devices:
#   - DESKTOP-XXXXXXX / LAPTOP-XXXXXXX  (Windows 10/11 auto-generated)
#   - Sarahs-MacBook-Pro                 (macOS default)
#   - Kevins-ThinkPad                    (branded PC)
# Names come from rig(1)'s bundled US name database, not from this file,
# so the source code doesn't reveal an enumerable list.
#
# Runtime toggle:
#   systemctl start toggle-spoof   (or via Super+T → "Enable/Disable Spoof")
# State is tracked in /run/spoof-enabled (present = spoofing active).
# Defaults to enabled on boot.
#
# To test mid-session without the toggle:
#   systemctl restart randomize-hostname && systemctl restart NetworkManager
# (nmcli general reload is NOT enough — it reloads NM's main config,
# not connection profiles. NM must fully restart to re-read them.)
{
  pkgs,
  ...
}:
let
  randomize-hostname = pkgs.writeShellScript "randomize-hostname" ''
    rand() {
      local max=$1
      local num
      num=$(${pkgs.coreutils}/bin/od -An -tu4 -N4 /dev/urandom | ${pkgs.coreutils}/bin/tr -d ' ')
      echo $((num % max))
    }

    # Generate N random characters from [A-Z0-9] — identical distribution
    # to real Windows auto-generated hostnames
    rand_alnum() {
      local len=$1
      ${pkgs.coreutils}/bin/head -c 64 /dev/urandom \
        | ${pkgs.coreutils}/bin/base64 \
        | ${pkgs.coreutils}/bin/tr -dc 'A-Z0-9' \
        | ${pkgs.coreutils}/bin/head -c "$len"
    }

    # Get a random first name from rig's bundled name database
    rand_name() {
      ${pkgs.rig}/bin/rig | ${pkgs.coreutils}/bin/head -1 | ${pkgs.gawk}/bin/awk '{print $1}'
    }

    PATTERN=$(rand 5)

    case $PATTERN in
      0|1)
        NEW_HOSTNAME="DESKTOP-$(rand_alnum 7)"
        ;;
      2)
        NEW_HOSTNAME="LAPTOP-$(rand_alnum 7)"
        ;;
      3)
        NAME=$(rand_name)
        MODELS=("MacBook-Pro" "MacBook-Air" "iMac")
        MODEL="''${MODELS[$(rand ''${#MODELS[@]})]}"
        NEW_HOSTNAME="''${NAME}s-''${MODEL}"
        ;;
      4)
        NAME=$(rand_name)
        TYPES=("ThinkPad" "HP-Laptop" "XPS" "Acer-Laptop")
        TYPE="''${TYPES[$(rand ''${#TYPES[@]})]}"
        NEW_HOSTNAME="''${NAME}s-''${TYPE}"
        ;;
    esac

    # Save the real hardware MAC before NM starts and randomizes it.
    # This runs Before=NetworkManager.service, so the interface still
    # has the permanent address. Used by the toggle notification.
    ${pkgs.coreutils}/bin/cat /sys/class/net/wl*/address 2>/dev/null \
      | ${pkgs.coreutils}/bin/head -1 > /run/real-mac

    # Patch all saved NM connections to send our hostname via DHCP.
    # On boot this runs before NM (Before=NetworkManager.service), so NM
    # reads the updated files on first startup.
    for conn in /etc/NetworkManager/system-connections/*; do
      [ -f "$conn" ] || continue

      # IPv4 DHCP hostname (Option 12).
      # IPv6 is not patched — NM's DHCPv6 client doesn't send a hostname
      # by default (verified via tcpdump on port 546/547).
      if ${pkgs.gnugrep}/bin/grep -q '^\[ipv4\]' "$conn"; then
        if ${pkgs.gnugrep}/bin/grep -q '^dhcp-hostname=' "$conn"; then
          ${pkgs.gnused}/bin/sed -i "s/^dhcp-hostname=.*/dhcp-hostname=$NEW_HOSTNAME/" "$conn"
        else
          ${pkgs.gnused}/bin/sed -i "/^\[ipv4\]/a dhcp-hostname=$NEW_HOSTNAME" "$conn"
        fi
      fi

      # DHCPv6 DUID — default is a stable UUID that persists across MAC
      # changes, making it a tracking vector. Setting dhcp-duid=ll derives
      # it from the link-layer (MAC) address instead, so it rotates
      # automatically with MAC randomization.
      if ${pkgs.gnugrep}/bin/grep -q '^\[ipv6\]' "$conn"; then
        if ${pkgs.gnugrep}/bin/grep -q '^dhcp-duid=' "$conn"; then
          ${pkgs.gnused}/bin/sed -i "/^\[ipv6\]/,/^\[/{s/^dhcp-duid=.*/dhcp-duid=ll/}" "$conn"
        else
          ${pkgs.gnused}/bin/sed -i "/^\[ipv6\]/a dhcp-duid=ll" "$conn"
        fi
      fi
    done

    # Save state so the toggle menu can show the spoofed identity
    echo "$NEW_HOSTNAME" > /run/spoof-hostname
    ${pkgs.coreutils}/bin/touch /run/spoof-enabled
  '';

  # Undo spoofing: remove spoofed DHCP hostname, restore real MAC
  # (cloned-mac-address=permanent overrides the NixOS default of "random"),
  # and restore default DUID.
  disable-spoof = pkgs.writeShellScript "disable-spoof" ''
    for conn in /etc/NetworkManager/system-connections/*; do
      [ -f "$conn" ] || continue
      ${pkgs.gnused}/bin/sed -i '/^dhcp-hostname=/d' "$conn"
      ${pkgs.gnused}/bin/sed -i '/^dhcp-duid=/d' "$conn"
      ${pkgs.gnused}/bin/sed -i '/^cloned-mac-address=/d' "$conn"

      # Force real MAC on wifi connections
      if ${pkgs.gnugrep}/bin/grep -q '^\[wifi\]' "$conn"; then
        ${pkgs.gnused}/bin/sed -i '/^\[wifi\]/a cloned-mac-address=permanent' "$conn"
      fi

      # Force real MAC on ethernet connections
      if ${pkgs.gnugrep}/bin/grep -q '^\[802-3-ethernet\]' "$conn"; then
        ${pkgs.gnused}/bin/sed -i '/^\[802-3-ethernet\]/a cloned-mac-address=permanent' "$conn"
      fi
    done
    ${pkgs.coreutils}/bin/rm -f /run/spoof-enabled /run/spoof-hostname
    /run/current-system/sw/bin/systemctl restart NetworkManager
  '';

  # Toggle spoofing on/off based on current state
  toggle-spoof = pkgs.writeShellScript "toggle-spoof" ''
    if [ -f /run/spoof-enabled ]; then
      ${disable-spoof}
    else
      # Remove any "permanent" MAC overrides so NM falls back to the
      # default "random" from NixOS config
      for conn in /etc/NetworkManager/system-connections/*; do
        [ -f "$conn" ] || continue
        ${pkgs.gnused}/bin/sed -i '/^cloned-mac-address=/d' "$conn"
      done
      ${randomize-hostname}
      /run/current-system/sw/bin/systemctl restart NetworkManager
    fi
  '';
in
{
  # Randomize MAC on every connection
  networking.networkmanager = {
    wifi.macAddress = "random";
    ethernet.macAddress = "random";
  };

  # Disable LLMNR — prevents systemd-resolved from answering link-local
  # multicast name queries with the real hostname. LLMNR is a Microsoft
  # protocol where devices on the same subnet can resolve each other's
  # hostnames without DNS; disabling it has no effect on normal DNS.
  services.resolved.settings.Resolve.LLMNR = "false";

  # Disable Avahi hostname publishing — Avahi broadcasts "hostname.local"
  # to the network via mDNS. With publish disabled, we can still discover
  # network printers and other services, but don't announce ourselves.
  services.avahi.publish.enable = false;

  # Generate a random hostname and patch NM connection files before NM
  # starts, so DHCP requests use the spoofed name from the first packet.
  systemd.services.randomize-hostname = {
    description = "Randomize DHCP hostname for network privacy";
    wantedBy = [ "multi-user.target" ];
    before = [ "NetworkManager.service" ];
    after = [ "systemd-hostnamed.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = randomize-hostname;
    };
  };

  # Toggle service — invoked by the user (Super+T menu) to flip spoofing
  # on or off at runtime. Runs as root so it can modify NM connections.
  systemd.services.toggle-spoof = {
    description = "Toggle network identity spoofing";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = toggle-spoof;
    };
  };
}
