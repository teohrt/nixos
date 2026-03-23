# Packages that should be installed for all users - root in mind
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    git
    neovim
  ];
}
