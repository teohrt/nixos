{ config, pkgs, ... }:

{

  home.username = "trace";
  home.homeDirectory = "/home/trace";

  imports = [
    ./user-apps.nix
  ];

  programs.git.enable = true;
  programs.git.settings.user = {
    name = "Trace Ohrt";
    email = "teohrt18@gmail.com";
  };

  # alacritty - a cross-platform, GPU-accelerated terminal emulator
  programs.alacritty = {
    enable = true;
    settings = {
      env.TERM = "xterm-256color";
      font = {
        size = 12;
        draw_bold_text_with_bright_colors = true;
      };
      scrolling.multiplier = 5;
      selection.save_to_clipboard = true;
    };
  };

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.11";
}