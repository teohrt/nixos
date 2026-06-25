# Network stack: NetworkManager with wpa_supplicant, systemd-resolved for DNS.
# NM provides D-Bus interface for Noctalia Shell's Network widget.
_: {
  networking.networkmanager.enable = true;

  # DNS resolution
  services.resolved.enable = true;
}
