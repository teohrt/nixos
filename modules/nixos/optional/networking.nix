# Network stack: NetworkManager with iwd backend, systemd-resolved for DNS.
# NM provides D-Bus interface for Noctalia Shell's Network widget.
# iwd backend preserves compatibility with impala WiFi TUI (talks to iwd over D-Bus).
{ ... }:
{
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";  # use iwd instead of wpa_supplicant
  };

  # iwd — used by NetworkManager as wifi backend
  networking.wireless.iwd.enable = true;
  networking.wireless.iwd.settings = {
    General = {
      EnableNetworkConfiguration = false;  # NetworkManager handles DHCP, not iwd
    };
    Settings.AutoConnect = true;
  };

  # DNS resolution
  services.resolved.enable = true;

  # NetworkManager handles wait-online itself
  systemd.network.wait-online.enable = false;
}
