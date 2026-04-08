{ pkgs, config, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    profiles.default.userSettings = {
      "window.backgroundOpacity" = 0.9;
    };
  };
}
