{ config, pkgs, pkgs-walker, ... }:

let
  powerMenu = pkgs.writeShellScriptBin "power-menu" ''
    CHOICE=$(printf "Shutdown\nRestart\nLock\nSuspend\nLog Out" \
      | ${pkgs-walker.walker}/bin/walker --dmenu -N -H)
    case "$CHOICE" in
      Shutdown)  systemctl poweroff ;;
      Restart)   systemctl reboot ;;
      Lock)      hyprlock ;;
      Suspend)   systemctl suspend ;;
      "Log Out") hyprctl dispatch exit ;;
    esac
  '';
in
{
  home.username = "trace";
  home.homeDirectory = "/home/trace";


  programs.btop.enable = true;

  dconf.settings = {
    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
    };
  };

  imports = [
    ./user-apps.nix
    ./git.nix
    ./hyprland.nix
    ./waybar.nix
    ./hyprpaper.nix
    ./alacritty.nix
    ./walker.nix
    ./hyprlock.nix
    ./hypridle.nix
    ./vscode.nix
  ];

  home.packages = [ powerMenu ];

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.11";
}
