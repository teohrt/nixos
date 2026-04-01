{ ... }: {
  programs.alacritty = {
    enable = true;
    settings = {
      window.padding = {
        x = 12;
        y = 12;
      };
    };
  };
}
