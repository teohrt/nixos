{ pkgs, lib, pkgs-walker, ... }:

let
  # Wallpapers grouped by theme. Each theme maps to a subdirectory under assets/.
  # Add new themes or wallpapers here — no naming conventions needed on the files.
  # animated = true  → displayed via mpvpaper (supports MP4/GIF)
  # animated = false → displayed via hyprpaper (static images only)
  themes = [
    {
      name = "Nord";
      wallpapers = [
        { name = "Mountain";   path = ../../assets/nord/mountain.png;   animated = false; }
        { name = "Black Hole"; path = ../../assets/nord/black_hole.mp4; animated = true;  }
      ];
    }
    {
      name = "Everforest";
      wallpapers = [
        { name = "Mist Forest"; path = ../../assets/everforest/mist_forest.png; animated = false; }
      ];
    }
  ];

  # Flat list of all wallpapers with display labels for the walker picker.
  # Format: "Theme / Name · animated" or "Theme / Name · static"
  allWallpapers = lib.concatMap (theme:
    map (w: w // {
      label = "${theme.name} / ${w.name} · ${if w.animated then "animated" else "static"}";
    }) theme.wallpapers
  ) themes;

  staticWallpapers = lib.filter (w: !w.animated) allWallpapers;

  # Walker dmenu picker — presents all wallpapers and switches to the chosen one.
  wallpaperPicker = pkgs.writeShellScriptBin "wallpaper-picker" ''
    CHOICE=$(printf '${lib.concatStringsSep "\\n" (map (w: w.label) allWallpapers)}' \
      | ${pkgs-walker.walker}/bin/walker --dmenu -N -H)

    case "$CHOICE" in
      ${lib.concatStringsSep "\n      " (map (w:
        if !w.animated then ''
          "${w.label}")
              pkill mpvpaper 2>/dev/null || true
              if ! pgrep -x hyprpaper > /dev/null; then
                hyprpaper &
                sleep 0.5
              fi
              hyprctl hyprpaper wallpaper ",${toString w.path}"
              ;;''
        else ''
          "${w.label}")
              pkill hyprpaper 2>/dev/null || true
              pkill mpvpaper 2>/dev/null || true
              ${lib.getExe pkgs.mpvpaper} -o 'loop' '*' ${toString w.path} &
              ;;''
      ) allWallpapers)}
    esac
  '';
in
{
  home.packages = [ wallpaperPicker ];

  # Stylix's hyprpaper target is disabled so we can manage it ourselves.
  # Stylix still uses its static image (in stylix.nix) for color scheme generation.
  stylix.targets.hyprpaper.enable = false;

  services.hyprpaper = {
    enable = true;
    settings = {
      # Preload all static wallpapers so switching between them is instant.
      preload   = map (w: toString w.path) staticWallpapers;
      # Default to the first static wallpaper on startup.
      wallpaper = [ ",${toString (builtins.head staticWallpapers).path}" ];
    };
  };

  wayland.windowManager.hyprland.settings = {
    bind = [
      "$mod SHIFT, W, exec, wallpaper-picker"
    ];
  };
}
