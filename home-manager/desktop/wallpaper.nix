{ pkgs, lib, pkgs-walker, ... }:

let
  # Wallpapers grouped by theme. Each theme maps to a subdirectory under assets/.
  # Add new themes or wallpapers here — no naming conventions needed on the files.
  # animated = true  → displayed via mpvpaper (supports MP4/GIF)
  # animated = false → displayed via hyprpaper (static images only)
  # specialisation = null   → Nord is the default NixOS config, no switch needed
  # specialisation = "name" → matches a specialisation defined in nixos/themes.nix
  themes = [
    {
      name = "Nord";
      specialisation = null;
      wallpapers = [
        { name = "Mountain";   path = ../../assets/nord/mountain.png;   animated = false; }
        { name = "Black Hole"; path = ../../assets/nord/black_hole.mp4; animated = true;  }
      ];
    }
    {
      name = "Everforest";
      specialisation = "everforest";
      wallpapers = [
        { name = "Mist Forest"; path = ../../assets/everforest/mist_forest.png; animated = false; }
      ];
    }
  ];

  # Flat list of all wallpapers with display labels for the walker picker.
  # Format: "Theme / Name · animated" or "Theme / Name · static"
  # Each entry carries the theme's specialisation name (null for the default theme).
  allWallpapers = lib.concatMap (theme:
    map (w: w // {
      label = "${theme.name} / ${w.name} · ${if w.animated then "animated" else "static"}";
      specialisation = theme.specialisation;
    }) theme.wallpapers
  ) themes;

  staticWallpapers = lib.filter (w: !w.animated) allWallpapers;

  # Emit the sudo command to activate a specialisation (or revert to default).
  # This runs switch-to-configuration which activates the pre-built system config,
  # including re-running home-manager activation to update all app configs on disk.
  switchCmd = w:
    if w.specialisation == null
    then "sudo /run/current-system/bin/switch-to-configuration switch"
    else "sudo /run/current-system/specialisation/${w.specialisation}/bin/switch-to-configuration switch";

  # Walker dmenu picker — presents all wallpapers and switches to the chosen one.
  # Order of operations:
  #   1. Activate the NixOS specialisation first — this may restart systemd services.
  #   2. Set the wallpaper after — so any service restarts don't conflict with our state.
  #   3. Restart waybar — it reads its config on startup so it picks up the new color scheme.
  wallpaperPicker = pkgs.writeShellScriptBin "wallpaper-picker" ''
    CHOICE=$(printf '${lib.concatStringsSep "\\n" (map (w: w.label) allWallpapers)}' \
      | ${pkgs-walker.walker}/bin/walker --dmenu -N -H)

    case "$CHOICE" in
      ${lib.concatStringsSep "\n      " (map (w:
        if !w.animated then ''
          "${w.label}")
              ${switchCmd w}
              pkill mpvpaper 2>/dev/null || true
              systemctl --user start hyprpaper.service
              # Wait for hyprpaper socket to be ready before issuing commands
              until hyprctl hyprpaper listloaded &>/dev/null; do sleep 0.1; done
              hyprctl hyprpaper preload "${toString w.path}"
              hyprctl hyprpaper wallpaper ",${toString w.path}"
              systemctl --user restart waybar.service
              ;;''
        else ''
          "${w.label}")
              ${switchCmd w}
              systemctl --user stop hyprpaper.service
              pkill mpvpaper 2>/dev/null || true
              ${lib.getExe pkgs.mpvpaper} -o 'loop' '*' ${toString w.path} &
              systemctl --user restart waybar.service
              ;;''
      ) allWallpapers)}
    esac
  '';
in
{
  home.packages = [ wallpaperPicker ];

  # Stylix's hyprpaper target is disabled so we can manage it ourselves.
  # Stylix still uses its static image (in stylix.nix) for color scheme generation.
  stylix.targets.hyprpaper.enable = lib.mkForce false;

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
