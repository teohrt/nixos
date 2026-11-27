{ pkgs, ... }:
{
  imports = [
    ./hardware.nix
  ];

  networking.hostName = "alpha";

  services = {
    xserver = {
      enable = true;
      desktopManager.lxqt.enable = true;
    };
    greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd startlxqt";
        user = "trace";
      };
      settings.initial_session = {
        command = "startlxqt";
        user = "trace";
      };
    };
  };

  system.stateVersion = "26.05";
}
