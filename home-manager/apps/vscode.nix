{ pkgs, osConfig, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    profiles.default.userSettings = {
      "window.backgroundOpacity" = osConfig.stylix.opacity.applications;
    };
  };
}
