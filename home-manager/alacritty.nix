{ ... }: {
  programs.alacritty = {
    enable = true;
    settings = {
      window.opacity = 0.85;
      window.padding = {
        x = 12;
        y = 12;
      };
    };
  };
}
