# Terminal emulator with cursor trail and smooth scrolling. Styled by Stylix, but with fixed dark background.
{ lib, pkgs, pkgs-kitty, config, ... }:

let
  # Unfloat the active window if it's floating (used before kitty splits)
  unfloatIfFloating = pkgs.writeShellScript "unfloat-if-floating" ''
    floating=$(hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.floating')
    if [[ "$floating" == "true" ]]; then
      hyprctl dispatch togglefloating
    fi
  '';
in
{
  programs.kitty = {
    enable = true;
    package = pkgs-kitty.kitty;
    settings = {
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

      # Disable confirm on close
      confirm_os_window_close = 0;

      # Enable remote control for session management
      allow_remote_control = "yes";
      listen_on = "unix:/tmp/kitty-socket";

      # Tabs and layouts
      enabled_layouts = "splits,stack";
      tab_bar_edge = "bottom";
      tab_bar_margin_height = "0 0";
      startup_session = "~/.config/kitty/startup.conf";
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
      "ctrl+enter" = "combine : launch --type=background ${unfloatIfFloating} : launch --location=split --cwd=current";
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

      # Font size
      "ctrl+equal" = "change_font_size all +1.0";
      "ctrl+minus" = "change_font_size all -1.0";

    };

    # Applied AFTER Stylix's base16 include, so this actually overrides the background
    extraConfig = ''
      font_size 16
      placement_strategy top-left
      background #0d0f14
      tab_bar_style separator
      tab_separator ""
      tab_title_template " {title} "
      tab_bar_margin_color #${config.lib.stylix.colors.base0D}
      tab_bar_background #${config.lib.stylix.colors.base0D}
      inactive_tab_background #${config.lib.stylix.colors.base0D}
      inactive_tab_foreground #000000
      active_tab_background #${config.lib.stylix.colors.base0B}
      active_tab_foreground #000000
      active_tab_font_style bold
      active_border_color #${config.lib.stylix.colors.base0D}
      inactive_border_color #2e3440
    '';
  };

  xdg.configFile."kitty/startup.conf".text = ''
    new_tab work
    cd ~/Dev/work
    launch zsh

    new_tab misc
    cd ~/Dev
    launch zsh

    new_tab nixos
    cd ~/Dev/other/nixos
    launch zsh

    new_tab dotfiles
    cd ~/Dev/other/dotfiles
    launch zsh
  '';
}
