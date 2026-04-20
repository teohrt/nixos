# Terminal emulator. Styled by Stylix, but with fixed dark background.
# NOTE: Not currently imported — keeping config in case we switch back from Kitty.
{ lib, ... }: {
  programs.alacritty = {
    enable = true;
    settings = {
      # Fixed dark bg — overrides Stylix so light themes stay readable
      colors.primary.background = lib.mkForce "#0d0f14";
      window.padding = {
        x = 12;
        y = 12;
      };
      # macOS-style copy/paste keybindings
      keyboard.bindings = [
        { key = "C"; mods = "Super"; action = "Copy"; }
        { key = "V"; mods = "Super"; action = "Paste"; }
      ];
    };
  };
}
