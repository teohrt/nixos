{ pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    neovim
    eza
    croc
    fzf
    gawk
    gnumake
    home-manager
    localsend
    inputs.workmux.packages.${stdenv.hostPlatform.system}.default
    jq
    lazydocker
    ripgrep
    stow
    tmux
    tree
    vlc
    which
    zoxide
  ];
}
