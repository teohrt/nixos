{ pkgs, osConfig, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      arcticicestudio.nord-visual-studio-code
    ];
    profiles.default.userSettings = {
      "workbench.colorTheme" = "Nord";
      "window.backgroundOpacity" = osConfig.stylix.opacity.applications;
    };
  };
}
