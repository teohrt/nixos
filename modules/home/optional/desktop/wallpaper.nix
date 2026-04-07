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
        { name = "Mountain";   path = ../../../../assets/nord/mountain.png;   animated = false; }
        { name = "Black Hole"; path = ../../../../assets/nord/black_hole.mp4; animated = true;  }
      ];
    }
    {
      name = "Gruvbox";
      specialisation = "gruvbox";
      wallpapers = [
        { name = "Mist Forest"; path = ../../../../assets/gruvbox/mist_forest.png; animated = false; }
        { name = "Leaves";      path = ../../../../assets/gruvbox/leaves.mp4;       animated = true;  }
      ];
    }
    {
      name = "Eris";
      specialisation = "eris";
      wallpapers = [
        { name = "Neon Car"; path = ../../../../assets/eris/neon-car.mp4; animated = true; }
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

  # The specialisation name passed to maybe_switch — empty string means Nord (base system).
  specArg = w: if w.specialisation == null then "" else w.specialisation;

  # Walker dmenu picker — presents all wallpapers and switches to the chosen one.
  # Order of operations:
  #   1. Activate the NixOS specialisation first — this may restart systemd services.
  #   2. Set the wallpaper after — so any service restarts don't conflict with our state.
  #   3. Restart waybar via systemd — it reads its config on startup so it picks up the new colors.
  wallpaperPicker = pkgs.writeShellScriptBin "wallpaper-picker" ''
    CHOICE=$(printf '${lib.concatStringsSep "\\n" (map (w: w.label) allWallpapers)}' \
      | ${pkgs-walker.walker}/bin/walker --dmenu -N -H)

    # Activate the target specialisation only if it isn't already active.
    # Compares resolved store paths — switching wallpapers within the same theme skips the switch.
    maybe_switch() {
      local spec="$1"
      local target
      if [ -z "$spec" ]; then
        target=$(readlink -f /nix/var/nix/profiles/system)
      else
        target=$(readlink -f /nix/var/nix/profiles/system/specialisation/"$spec")
      fi
      [ "$(readlink -f /run/current-system)" = "$target" ] && return 0
      if [ -z "$spec" ]; then
        sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
      else
        sudo /nix/var/nix/profiles/system/specialisation/"$spec"/bin/switch-to-configuration switch
      fi
    }

    # Restart daemons that load their GTK theme or config once at startup.
    # Heavy apps (VS Code, Obsidian, Firefox, Spotify) are left for the user to reopen.
    restart_themed_daemons() {
      systemctl --user restart waybar.service
      systemctl --user restart mako.service
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
              if maybe_switch "${specArg w}"; then
                notify-send "Theme" "Switched to ${w.label}"
              else
                notify-send -u critical "Theme switch failed" "Check sudo rules in modules/nixos/optional/themes.nix"
              fi

              pkill mpvpaper 2>/dev/null || true
              systemctl --user start hyprpaper.service
              # Wait for hyprpaper socket to be ready before issuing commands
              until hyprctl hyprpaper listloaded &>/dev/null; do sleep 0.1; done
              hyprctl hyprpaper preload "${toString w.path}"
              hyprctl hyprpaper wallpaper ",${toString w.path}"
              restart_themed_daemons
              ;;''
        else ''
          "${w.label}")
              if maybe_switch "${specArg w}"; then
                notify-send "Theme" "Switched to ${w.label}"
              else
                notify-send -u critical "Theme switch failed" "Check sudo rules in modules/nixos/optional/themes.nix"
              fi

              systemctl --user stop hyprpaper.service
              pkill mpvpaper 2>/dev/null || true
              ${lib.getExe pkgs.mpvpaper} -o 'loop' '*' ${toString w.path} &
              restart_themed_daemons
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
