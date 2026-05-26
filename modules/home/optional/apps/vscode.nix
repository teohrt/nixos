# VS Code editor. Styled by Stylix.
{ pkgs, config, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    profiles.default = {
      userSettings = {
        "window.backgroundOpacity" = 1; # opaque background (no transparency)
        "workbench.sideBar.location" = "right"; # file explorer on right side
        "update.mode" = "none"; # updates managed by Nix
        "window.menuBarVisibility" = "hidden";
        "extensions.ignoreRecommendations" = true;
        "git.openRepositoryInParentFolders" = "never";
        "chat.commandCenter.enabled" = false;
        "chat.enabled" = false;
        "workbench.secondarySideBar.visible" = false;
      };
      extensions = with pkgs.vscode-extensions; [
        redhat.vscode-yaml
      ];
    };
  };
}
