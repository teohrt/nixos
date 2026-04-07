{ ... }:
{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false; # start daemon on-demand via socket activation instead of at boot
  };
}
