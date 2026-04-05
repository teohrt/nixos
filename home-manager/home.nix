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

  # Darken Nautilus background so text stays readable across light and dark themes.
  # shade() is a GTK CSS function: values < 1 darken, > 1 lighten.
  stylix.targets.gtk.extraCss = ''
    .nautilus-window {
      background-color: shade(@window_bg_color, 0.75);
    }
  '';

  dconf.settings = {
    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
    };
  };

  imports = [
    ./user-apps.nix
    ./desktop/hyprland.nix
    ./desktop/waybar.nix
    ./desktop/walker.nix
    ./desktop/wallpaper.nix
    ./desktop/hyprlock.nix
    ./desktop/hypridle.nix
    ./apps/git.nix
    ./apps/alacritty.nix
    ./apps/firefox.nix
    ./apps/vscode.nix
    ./apps/obsidian.nix
    ./apps/spicetify.nix
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
