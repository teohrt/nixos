# Wine for running Windows software outside of Steam/Proton.
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    wineWowPackages.stable # wine64 + wine32, covers most apps/installers
    winetricks # installs common DLLs/runtimes apps depend on
    bottles # GUI frontend for managing per-app wine prefixes
  ];

  # 32-bit app support (many Windows apps are still 32-bit)
  hardware.graphics.enable32Bit = true;
}
