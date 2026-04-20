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
      cursor_trail_start_threshold = 0; # no threshold, always trail from previous position

      # Cursor appearance
      cursor_shape = "beam";
      cursor_beam_thickness = "1.5";
      cursor_blink_interval = "0.5";

      # Disable confirm on close (like alacritty behavior)
      confirm_os_window_close = 0;
    };

    # macOS-style copy/paste keybindings
    keybindings = {
      "super+c" = "copy_to_clipboard";
      "super+v" = "paste_from_clipboard";
    };

    # Applied AFTER Stylix's base16 include, so this actually overrides the background
    extraConfig = ''
      background #0d0f14
    '';
  };
}
