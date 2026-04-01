{ ... }: {
  programs.alacritty = {
    enable = true;
    settings = {
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
