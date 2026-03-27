{ pkgs, ... }:

let
  hyprRofiMenu = pkgs.writeShellScript "hypr-rofi-menu" ''
    pkill -x rofi 2>/dev/null || true
    exec rofi -show combi
  '';

  hyprScreenshot = pkgs.writeShellScript "hypr-screenshot" ''
    ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.wl-clipboard}/bin/wl-copy
  '';
in
{
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      monitor = ",preferred,auto,auto";

      "$terminal" = "alacritty";
      "$menu" = "${hyprRofiMenu}";
      "$mod" = "SUPER";

      exec-once = [
        "${pkgs.mako}/bin/mako"
        "${pkgs.hyprpaper}/bin/hyprpaper"
        "waybar"
      ];

      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        layout = "dwindle";
      };

      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
      };

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0;
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      # key bindings
      bind = [
        "$mod, Return, exec, $terminal"
        "$mod, W, killactive"
        "$mod, ESC, exit"
        "$mod, V, togglefloating"
        "$mod, SPACE, exec, $menu"
        "$mod, J, togglesplit"

        # focus
        "$mod, left,  movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up,    movefocus, u"
        "$mod, down,  movefocus, d"

        # workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"

        # move window to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"

        # screenshot
        ", Print, exec, ${hyprScreenshot}"
      ];

      # mouse bindings
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };
}
