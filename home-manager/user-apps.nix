# Packages that should be installed to the user profile.
{ pkgs, ... }: {
  home.packages = with pkgs; [
    neofetch
    ripgrep # recursively searches directories for a regex pattern
    jq # A lightweight and flexible command-line JSON processor
    eza # A modern replacement for ‘ls’
    fzf # A command-line fuzzy finder
    which
    tree
    gawk
    vscode
    google-chrome
    btop
    alacritty
  ];
}
