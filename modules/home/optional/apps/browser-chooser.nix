# Browser chooser: intercepts link opens and prompts which Chrome profile to use.
# Registers as the default handler for http/https so XDG routes all links through it.
{ pkgs, ... }:
let
  browser-chooser = pkgs.writeShellScriptBin "browser-chooser" ''
    url="$1"

    choice=$(printf 'Work\nPersonal' | ${pkgs.walker}/bin/walker --dmenu --placeholder "Open link in...")

    case "$choice" in
      Work)     profile="Default" ;;
      Personal) profile="Profile 1" ;;
      *)        exit 0 ;;
    esac

    ${pkgs.google-chrome}/bin/google-chrome-stable --profile-directory="$profile" "$url" &
    sleep 0.3
    ${pkgs.hyprland}/bin/hyprctl dispatch 'hl.dsp.focus({ window = "class:google-chrome" })'
  '';

  desktopEntry = pkgs.makeDesktopItem {
    name = "browser-chooser";
    desktopName = "Browser Chooser";
    exec = "${browser-chooser}/bin/browser-chooser %U";
    mimeTypes = [
      "text/html"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/about"
      "x-scheme-handler/unknown"
    ];
    categories = [
      "Network"
      "WebBrowser"
    ];
    type = "Application";
  };
in
{
  home.packages = [
    browser-chooser
    desktopEntry
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "browser-chooser.desktop";
      "x-scheme-handler/http" = "browser-chooser.desktop";
      "x-scheme-handler/https" = "browser-chooser.desktop";
      "x-scheme-handler/about" = "browser-chooser.desktop";
      "x-scheme-handler/unknown" = "browser-chooser.desktop";
    };
  };
}
