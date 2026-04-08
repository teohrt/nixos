{ pkgs, config, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    profiles.default.userSettings = {
      "window.backgroundOpacity" = config.stylix.opacity.applications;
    };
  };
}
