# Terminal emulator with animated cursor trail. Styled by Stylix, but with fixed dark background.
{ lib, ... }: {
  programs.kitty = {
    enable = true;
    settings = {
      # Window padding (kitty uses single value for all sides)
      window_padding_width = 12;

      # Animated cursor trail (the feature you want)
      cursor_trail = 3;
      cursor_trail_decay = "0.1 0.4";
      cursor_trail_start_threshold = 0;

      # Cursor appearance
      cursor_shape = "beam";
      cursor_beam_thickness = "1.5";
      cursor_blink_interval = "0.5";

      # Disable confirm on close (like alacritty behavior)
      confirm_os_window_close = 0;

      # Tabs and layouts
      enabled_layouts = "splits,stack";
      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";
      tab_title_template = "{index} - {title}";
    };

    # Keybindings mirroring Hyprland (Ctrl instead of Super)
    keybindings = {
      # Copy/paste
      "super+c" = "copy_to_clipboard";
      "super+v" = "paste_from_clipboard";

      # Window (split) focus - Ctrl+arrows
      "ctrl+left" = "neighboring_window left";
      "ctrl+right" = "neighboring_window right";
      "ctrl+up" = "neighboring_window up";
      "ctrl+down" = "neighboring_window down";

      # Window (split) movement - Ctrl+Shift+arrows
      "ctrl+shift+left" = "move_window left";
      "ctrl+shift+right" = "move_window right";
      "ctrl+shift+up" = "move_window up";
      "ctrl+shift+down" = "move_window down";

      # Window management
      "ctrl+q" = "close_window";
      "ctrl+enter" = "launch --location=split --cwd=current";
      "ctrl+shift+enter" = "new_tab_with_cwd";
      "ctrl+f" = "toggle_layout stack";
      "ctrl+j" = "layout_action rotate";

      # Tab switching - Ctrl+1-9
      "ctrl+1" = "goto_tab 1";
      "ctrl+2" = "goto_tab 2";
      "ctrl+3" = "goto_tab 3";
      "ctrl+4" = "goto_tab 4";
      "ctrl+5" = "goto_tab 5";
      "ctrl+6" = "goto_tab 6";
      "ctrl+7" = "goto_tab 7";
      "ctrl+8" = "goto_tab 8";
      "ctrl+9" = "goto_tab 9";

      # Tab management
      "ctrl+shift+t" = "detach_window new-tab";
      "ctrl+t" = "set_tab_title";
    };

    # Applied AFTER Stylix's base16 include, so this actually overrides the background
    extraConfig = ''
      background #0d0f14
    '';
  };
}
