# Network stack: NetworkManager with iwd backend, systemd-resolved for DNS.
# NM provides D-Bus interface for Noctalia Shell's Network widget.
# iwd backend preserves compatibility with impala WiFi TUI (talks to iwd over D-Bus).
{ ... }:
{
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";  # use iwd instead of wpa_supplicant
  };

  # DNS resolution
  services.resolved.enable = true;
}
