{ ... }: {
  programs.alacritty = {
    enable = true;
    settings = {
      window.opacity = 0.6;
      window.padding = {
        x = 12;
        y = 12;
      };
    };
  };
}
