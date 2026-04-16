# Docker container runtime with socket activation (starts on first use, not at boot)
{ ... }:
{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false; # start daemon on-demand via socket activation instead of at boot
  };
}
