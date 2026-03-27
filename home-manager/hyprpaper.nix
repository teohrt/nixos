{ ... }: {
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [ "${../assets/wallpaper.png}" ];
      wallpaper = [ ",${../assets/wallpaper.png}" ];
    };
  };
}
