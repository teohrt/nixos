# Terminal emulator with cursor trail and smooth scrolling. Styled by Stylix, but with fixed dark background.
{
  pkgs,
  config,
  ...
}:
{
  programs.kitty = {
    enable = true;
    package = pkgs.kitty;
    shellIntegration.mode = "enabled";
    shellIntegration.enableZshIntegration = false;
    settings = {
      remember_window_size = false;

      # Window padding (kitty uses single value for all sides)
      window_padding_width = 12;
      window_border_width = "0.5pt";
      draw_minimal_borders = "yes";

      # Animated cursor trail (the feature you want)
      cursor_trail = 5;
      cursor_trail_decay = "0.07 0.27";
      cursor_trail_start_threshold = 0;

      # Cursor appearance
      cursor_shape = "beam";
      cursor_beam_thickness = "1.5";
      cursor_blink_interval = "0.5";

      # Smooth scrolling (kitty 0.46+)
      pixel_scroll = true;
      momentum_scroll = "0.98";

      confirm_os_window_close = 2;

      # Launch tmux on startup
      shell = "${config.home.homeDirectory}/.config/tmux/start.sh";

      # Required for workmux kitty backend
      allow_remote_control = "yes";
      listen_on = "unix:$XDG_RUNTIME_DIR/kitty-socket";
    };

    keybindings = {
      "ctrl+equal" = "change_font_size all +1.0";
      "ctrl+minus" = "change_font_size all -1.0";
      # Send xterm-style sequences so tmux can recognize these key combos
      "ctrl+enter" = "send_text all \\x1b[27;5;13~";
      "ctrl+shift+left" = "send_text all \\x1b[1;6D";
      "ctrl+shift+right" = "send_text all \\x1b[1;6C";
      "ctrl+shift+up" = "send_text all \\x1b[1;6A";
      "ctrl+shift+down" = "send_text all \\x1b[1;6B";
    };

    # Applied AFTER Stylix's base16 include, so this actually overrides the background
    extraConfig = ''
      font_size 15
      placement_strategy top-left
      background #${config.lib.stylix.colors.base01}
    '';
  };
}
