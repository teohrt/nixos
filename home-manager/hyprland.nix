{ ... }: {
  wayland.windowManager.hyprland = {
    enable = true;

    # disable systemd integration, as it conflicts with UWSM.
    systemd.enable = false;

    settings = {
      "$mod" = "SUPER";
      bind = [
        "$mod, T, exec, alacritty"
        "$mod, Q, killactive,"
      ];
      monitor = [
        "DP-1, 1920x1080@144, 0x0, 1"
      ];
      exec-once = [
        "waybar"
        "swww init"
      ];
    };
  };
}
