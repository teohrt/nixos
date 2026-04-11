{ ... }:
{
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

  # Disable wait-online — iwd manages wifi outside of networkd so no
  # interface ever reports online to networkd during boot
  systemd.network.wait-online.enable = false;
}
