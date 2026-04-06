{ lib, ... }: {
  programs.alacritty = {
    enable = true;
    settings = {
      colors.primary.background = lib.mkForce "#0d0f14"; # fixed dark bg — overrides Stylix so light themes stay readable
      window.padding = {
        x = 12;
        y = 12;
      };
      keyboard.bindings = [
        { key = "C"; mods = "Super"; action = "Copy"; }
        { key = "V"; mods = "Super"; action = "Paste"; }
      ];
    };
  };
}
