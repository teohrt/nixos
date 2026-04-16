# Network stack: iwd for WiFi, systemd-networkd for wired, systemd-resolved for DNS.
# Uses iwd instead of NetworkManager for compatibility with impala WiFi TUI.
{ ... }:
{
  # iwd manages wifi (required by impala TUI — talks directly to iwd over D-Bus)
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

  # Disable wait-online — iwd manages wifi outside of networkd so no
  # interface ever reports online to networkd during boot
  systemd.network.wait-online.enable = false;
}
