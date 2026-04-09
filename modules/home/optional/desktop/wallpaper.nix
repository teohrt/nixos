{ pkgs, lib, pkgs-walker, ... }:

let
  # Wallpapers fetched from URLs at build time.
  # To add a new wallpaper:
  #   1. Get the URL
  #   2. Run: nix-prefetch-url <url>
  #   3. Add entry below with name, url, and sha256
  wallpapers = [
    {
      name = "Dark - Black Hole";
      path = pkgs.fetchurl {
        url = "https://w.wallhaven.cc/full/po/wallhaven-pojl63.png";
        sha256 = "162yh1ppaizbmhc1vnnypjfjiyiyyfyj49hdbxhfzvps1pc94j8g";
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
      name = "Light - Nix";
      path = pkgs.fetchurl {
        url = "https://w.wallhaven.cc/full/q2/wallhaven-q2w1kd.png";
        sha256 = "116337wv81xfg0g0bsylzzq2b7nbj6hjyh795jfc9mvzarnalwd3";
      };
    }
    {
      name = "Blue Paraglider";
      path = pkgs.fetchurl {
        url = "https://w.wallhaven.cc/full/x1/wallhaven-x175wl.png";
        sha256 = "11i8fp8xfydvbhs75g0bp0lc60j7hskrhq2jmhl23lf3xwxjh0n4";
      };
    }
    {
      name = "Galaxy Canopy Pilot";
      path = pkgs.fetchurl {
        url = "https://w.wallhaven.cc/full/nr/wallhaven-nr2okq.jpg";
        sha256 = "1xgy6iyz61ha5l8zw562dpag0k93z0bkzjp0fgx0zbsr4lv9q7zb";
      };
    }
    {
      name = "Blue Squares";
      path = pkgs.fetchurl {
        url = "https://w.wallhaven.cc/full/4v/wallhaven-4vzeml.jpg";
        sha256 = "0akjdh1a7sj4yyx4xfhfayfvrryi68bnv1cqcvhwaddaidb2wfyw";
      };
    }
    {
      name = "Dark Leaves";
      path = pkgs.fetchurl {
        url = "https://w.wallhaven.cc/full/6k/wallhaven-6kgl3l.jpg";
        sha256 = "0wlwxmmrryj1yjmj43ql4xxfiiclg64881g2k6ryz2dzvzfwmqvz";
      };
    }
    {
      name = "Purple Hex";
      path = pkgs.fetchurl {
        url = "https://w.wallhaven.cc/full/01/wallhaven-01vwg0.jpg";
        sha256 = "0a3jk9fy2z8ac6vk2va5y3w188pcy595nbbfq244wcpznn995w55";
      };
    }
    {
      name = "4th Dimension";
      path = pkgs.fetchurl {
        url = "https://w.wallhaven.cc/full/6o/wallhaven-6o7y8x.jpg";
        sha256 = "1x63qnrkcmy0lvmqbygcl85iz6ahmii46023lx76np1rrpbpvaij";
      };
    }
    {
      name = "Blue Abstract";
      path = pkgs.fetchurl {
        url = "https://w.wallhaven.cc/full/y8/wallhaven-y8vvmd.jpg";
        sha256 = "0s5kllw8f7bnb1nlzl3dxcw3y9l7wfhxv7xpnmqvcg2k98l6q648";
      };
    }
    {
      name = "Urf";
      path = pkgs.fetchurl {
        url = "https://w.wallhaven.cc/full/47/wallhaven-47jpxv.jpg";
        sha256 = "1p3z8gjinyfzlrwfrbwfx48z7270jrxhprjbmkl97slr45fkvn6f";
      };
    }
    {
      name = "Final Frontier";
      path = pkgs.fetchurl {
        url = "https://w.wallhaven.cc/full/nm/wallhaven-nmpo19.jpg";
        sha256 = "005cv0afh7xj6i5kg0z9dc83fjf1w3400hx755z75chnwy69zp6i";
      };
    }
  ];

  defaultWallpaper = builtins.head wallpapers;

  # Walker dmenu picker for wallpapers
  wallpaperPicker = pkgs.writeShellScriptBin "wallpaper-picker" ''
    CHOICE=$(printf '${lib.concatStringsSep "\\n" (map (w: w.name) wallpapers)}' \
      | ${pkgs-walker.walker}/bin/walker --dmenu -N -H)

    case "$CHOICE" in
      ${lib.concatStringsSep "\n      " (map (w: ''
        "${w.name}")
            ${pkgs.swww}/bin/swww img "${w.path}" \
              --transition-type grow \
              --transition-duration 1 \
              --transition-fps 60 \
              --transition-pos center
            notify-send "Wallpaper" "Switched to ${w.name}"
            ;;''
      ) wallpapers)}
    esac
  '';
in
{
  home.packages = [
    wallpaperPicker
    pkgs.swww
  ];

  # Disable stylix hyprpaper since we use swww
  stylix.targets.hyprpaper.enable = lib.mkForce false;

  # swww daemon and initial wallpaper
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "${pkgs.swww}/bin/swww-daemon"
      "sleep 0.5 && ${pkgs.swww}/bin/swww img ${defaultWallpaper.path}"
    ];
    bind = [
      "$mod SHIFT, W, exec, wallpaper-picker"
    ];
  };
}
