{ ... }:

# Firefox renders its own UI (tabs, toolbar, address bar) using its internal CSS
# engine rather than GTK widgets, so it does not automatically inherit the stylix
# GTK theme the way Chrome does. Theming requires explicitly enabling the
# firefoxGnomeTheme target (which injects a generated userChrome.css) and telling
# stylix which profiles to apply it to via profileNames.
{
  programs.firefox = {
    enable = true;
    profiles.default = {
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "ui.systemUsesDarkColors" = 1;
      };
    };
  };

  stylix.targets.firefox = {
    profileNames = [ "default" ];
    firefoxGnomeTheme.enable = true;
  };
}
