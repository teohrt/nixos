{ ... }:

{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        grace = 0;
      };

    };
  };
}
