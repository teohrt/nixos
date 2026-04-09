{ pkgs, lib, pkgs-walker, ... }:

let
  # Wallpapers fetched from URLs at build time.
  # To add a new wallpaper:
  #   1. Get the URL
  #   2. Run: nix-prefetch-url <url>
  #   3. Add entry below with name, url, and sha256
  wallpapers = [
    {
      name = "Dark - Lake";
      path = pkgs.fetchurl {
        url = "https://w.wallhaven.cc/full/8x/wallhaven-8x225j.jpg";
        sha256 = "06q04fivqws6smn3plmyslf8s9xdykhrx3sa09vjnywrh5wjk3fq";
      };
    }
    {
      name = "Light - Lake";
      path = pkgs.fetchurl {
        url = "https://w.wallhaven.cc/full/21/wallhaven-21dlrg.jpg";
        sha256 = "11bgjl7pf3c0fdv85fvng6qn9r03x246f77zp4w1myrpng4glr6s";
      };
    }
    {
      name = "Dark - Black Hole";
      path = pkgs.fetchurl {
        url = "https://w.wallhaven.cc/full/po/wallhaven-pojl63.png";
        sha256 = "162yh1ppaizbmhc1vnnypjfjiyiyyfyj49hdbxhfzvps1pc94j8g";
      };
    }
    {
      name = "Light - Nix";
      path = pkgs.fetchurl {
        url = "https://w.wallhaven.cc/full/q2/wallhaven-q2w1kd.png";
        sha256 = "116337wv81xfg0g0bsylzzq2b7nbj6hjyh795jfc9mvzarnalwd3";
      };
    }
  ];

  # Walker dmenu picker for wallpapers
  wallpaperPicker = pkgs.writeShellScriptBin "wallpaper-picker" ''
    CHOICE=$(printf '${lib.concatStringsSep "\\n" (map (w: w.name) wallpapers)}' \
      | ${pkgs-walker.walker}/bin/walker --dmenu -N -H)

    case "$CHOICE" in
      ${lib.concatStringsSep "\n      " (map (w: ''
        "${w.name}")
            hyprctl hyprpaper preload "${w.path}"
            hyprctl hyprpaper wallpaper ",${w.path}"
            notify-send "Wallpaper" "Switched to ${w.name}"
            ;;''
      ) wallpapers)}
    esac
  '';
in
{
  home.packages = [ wallpaperPicker ];

  # Stylix's hyprpaper target is disabled so we can manage wallpapers ourselves.
  stylix.targets.hyprpaper.enable = lib.mkForce false;

  services.hyprpaper = {
    enable = true;
    settings = {
      # Preload all wallpapers so switching is instant.
      preload = map (w: toString w.path) wallpapers;
      # Default to the first wallpaper on startup.
      wallpaper = [ ",${toString (builtins.head wallpapers).path}" ];
    };
  };

  wayland.windowManager.hyprland.settings = {
    bind = [
      "$mod SHIFT, W, exec, wallpaper-picker"
    ];
  };
}
