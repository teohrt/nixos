{ ... }: {
  programs.alacritty = {
    enable = true;
    settings = {
      window.opacity = 0.85;
      colors.primary.background = "#0a0a0f";
      window.padding = {
        x = 12;
        y = 12;
      };
    };
  };
}
