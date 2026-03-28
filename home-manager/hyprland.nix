{ ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      monitor = ",preferred,auto,1.2";

      "$terminal" = "alacritty";
      "$menu" = "walker -N -H";
      "$mod" = "SUPER";

      exec-once = [
        "${pkgs.mako}/bin/mako"
        "waybar"
        "elephant"                                        # indexes apps for walker to search
        "sleep 2 && walker --gapplication-service"        # walker background service (delayed to let elephant index first)
      ];

      env = [
        "XCURSOR_SIZE,24"
        "XCURSOR_THEME,Adwaita"
        "HYPRCURSOR_SIZE,24"
        "HYPRCURSOR_THEME,Adwaita"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 0;
        layout = "dwindle";
      };

      animations = {
        enabled = true;
        bezier = "easeOutQuart, 0.25, 1, 0.5, 1";
        animation = [
          "windows, 1, 4, easeOutQuart, slide"
          "windowsOut, 1, 4, easeOutQuart, slide"
          "fade, 1, 4, easeOutQuart"
          "workspaces, 1, 4, easeOutQuart, slide"
        ];
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

      # window rules
      windowrulev2 = [
        "float, title:^(wifi)$"
        "size 900 600, title:^(wifi)$"
        "center, title:^(wifi)$"
        "float, title:^(bluetooth)$"
        "size 600 400, title:^(bluetooth)$"
        "center, title:^(bluetooth)$"
        "float, title:^(audio)$"
        "size 600 400, title:^(audio)$"
        "center, title:^(audio)$"
      ];

      # key bindings
      bind = [
        "$mod, Return, exec, $terminal"
        "$mod, Escape, exec, power-menu"
        "$mod SHIFT, Return, exec, google-chrome-stable"
        "$mod, F, fullscreen"
        "$mod SHIFT, F, exec, thunar"
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
        ", Print,       exec, hyprshot -m region --clipboard-only"
        "SHIFT, Print,  exec, hyprshot -m window --clipboard-only"
        "$mod, Print,   exec, hyprshot -m output --clipboard-only"
      ];

      # mouse bindings
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };
}
