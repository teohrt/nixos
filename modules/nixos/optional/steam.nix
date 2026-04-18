# Steam gaming platform. Requires system-level config for 32-bit libraries and
# FHS compatibility (Filesystem Hierarchy Standard - Steam expects /usr, /lib, etc.).
{ pkgs, ... }: {
  programs.steam = {
    enable = true;
    # Open ports for Steam Remote Play and local network game transfers
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # GameMode - optimizes system performance while gaming
  programs.gamemode.enable = true;

  # 32-bit graphics support (required by many Steam games)
  hardware.graphics.enable32Bit = true;
}
