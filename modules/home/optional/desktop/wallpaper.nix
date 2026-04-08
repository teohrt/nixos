{ pkgs, lib, pkgs-walker, ... }:

let
  # Wallpapers grouped by theme. Each theme maps to a subdirectory under assets/.
  # Add new themes or wallpapers here — no naming conventions needed on the files.
  # animated = true  → displayed via mpvpaper (supports MP4/GIF)
  # animated = false → displayed via hyprpaper (static images only)
  # hmTheme = the theme name used in homeConfigurations (e.g., "nord", "gruvbox", "eris")
  themes = [
    {
      name = "Nord";
      hmTheme = "nord";
      wallpapers = [
        { name = "Mountain";   path = ../../../../assets/nord/mountain.png;   animated = false; }
        { name = "Black Hole"; path = ../../../../assets/nord/black_hole.mp4; animated = true;  }
      ];
    }
    {
      name = "Gruvbox";
      hmTheme = "gruvbox";
      wallpapers = [
        { name = "Mist Forest"; path = ../../../../assets/gruvbox/mist_forest.png; animated = false; }
        { name = "Leaves";      path = ../../../../assets/gruvbox/leaves.mp4;       animated = true;  }
      ];
    }
    {
      name = "Eris";
      hmTheme = "eris";
      wallpapers = [
        { name = "Neon Car"; path = ../../../../assets/eris/neon-car.mp4; animated = true; speed = 0.5; }
      ];
    }
  ];

  # Flat list of all wallpapers with display labels for the walker picker.
  # Format: "Theme / Name · animated" or "Theme / Name · static"
  allWallpapers = lib.concatMap (theme:
    map (w: w // {
      label = "${theme.name} / ${w.name} · ${if w.animated then "animated" else "static"}";
      hmTheme = theme.hmTheme;
    }) theme.wallpapers
  ) themes;

  staticWallpapers = lib.filter (w: !w.animated) allWallpapers;

  # Walker dmenu picker — presents all wallpapers and switches to the chosen one.
  # Uses home-manager switch for fast theme changes (no sudo required).
  wallpaperPicker = pkgs.writeShellScriptBin "wallpaper-picker" ''
    CHOICE=$(printf '${lib.concatStringsSep "\\n" (map (w: w.label) allWallpapers)}' \
      | ${pkgs-walker.walker}/bin/walker --dmenu -N -H)

    # Determine the home-manager config name based on hostname
    # Maps hostname to the flake config prefix (e.g., framework-16 -> framework-16, framework-16 -> thinkpad)
    get_hm_prefix() {
      local hostname=$(hostname)
      case "$hostname" in
        framework-16) echo "framework-16" ;;
        my-thinkpad)  echo "thinkpad" ;;
        *)            echo "$hostname" ;;
      esac
    }

    # Track current theme to avoid unnecessary rebuilds
    CURRENT_THEME_FILE="$HOME/.cache/current-theme"
    CURRENT_THEME=$(cat "$CURRENT_THEME_FILE" 2>/dev/null || echo "")

    # Switch home-manager config to the target theme
    # Returns 0 and sets THEME_SWITCHED=1 if switch happened, THEME_SWITCHED=0 if already on theme
    THEME_SWITCHED=0
    maybe_switch() {
      local theme="$1"
      if [ "$CURRENT_THEME" = "$theme" ]; then
        THEME_SWITCHED=0
        return 0
      fi

      local prefix=$(get_hm_prefix)
      local config="trace@''${prefix}-''${theme}"

      notify-send "Theme" "Switching to $theme..." -t 2000

      # Run home-manager switch from the flake directory
      if ${pkgs.home-manager}/bin/home-manager switch --flake "$HOME/Dev/other/nixos#$config" 2>&1; then
        echo "$theme" > "$CURRENT_THEME_FILE"
        THEME_SWITCHED=1
        return 0
      else
        notify-send -u critical "Theme switch failed" "home-manager switch failed for $config"
        return 1
      fi
    }

    # Restart daemons that load their config once at startup.
    # Heavy apps (VS Code, Obsidian, Firefox, Spotify) are left for the user to reopen.
    restart_themed_daemons() {
      # Restart services in background so they don't block each other
      systemctl --user restart waybar.service &
      systemctl --user restart mako.service &
      # Restart walker background service so it picks up the new GTK theme.
      pkill -f "walker --gapplication-service" 2>/dev/null || true
      sleep 0.5 && walker --gapplication-service &
      # GTK4 apps load CSS once — kill so they get the new theme on next open.
      pkill nautilus 2>/dev/null || true
    }

    case "$CHOICE" in
      ${lib.concatStringsSep "\n      " (map (w:
        if !w.animated then ''
          "${w.label}")
              if maybe_switch "${w.hmTheme}"; then
                pkill mpvpaper 2>/dev/null || true
                systemctl --user start hyprpaper.service
                # Wait for hyprpaper socket to be ready before issuing commands
                until hyprctl hyprpaper listloaded &>/dev/null; do sleep 0.1; done
                hyprctl hyprpaper preload "${toString w.path}"
                hyprctl hyprpaper wallpaper ",${toString w.path}"
                [ "$THEME_SWITCHED" = "1" ] && restart_themed_daemons
                notify-send "Theme" "Switched to ${w.label}"
              fi
              ;;''
        else ''
          "${w.label}")
              if maybe_switch "${w.hmTheme}"; then
                systemctl --user stop hyprpaper.service
                pkill mpvpaper 2>/dev/null || true
                # speed is optional — only wallpapers with a speed attribute (e.g. Eris) override playback rate
                # panscan=1.0 fills the screen properly with fractional scaling
                ${lib.getExe pkgs.mpvpaper} -o 'loop panscan=1.0${if w ? speed then " speed=${toString w.speed}" else ""}' '*' ${toString w.path} &
                [ "$THEME_SWITCHED" = "1" ] && restart_themed_daemons
                notify-send "Theme" "Switched to ${w.label}"
              fi
              ;;''
      ) allWallpapers)}
    esac
  '';
in
{
  home.packages = [ wallpaperPicker ];

  # Stylix's hyprpaper target is disabled so we can manage it ourselves.
  # Stylix still uses its static image for color scheme generation.
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
