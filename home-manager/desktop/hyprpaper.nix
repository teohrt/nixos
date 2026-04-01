{ ... }:

# mpvpaper handles wallpaper display and is launched via Hyprland exec-once.
# hyprpaper is disabled — it only supports static images, not video.
# stylix still uses a static image (in stylix.nix) for color scheme generation,
# which is separate from what's displayed on screen.
{
  services.hyprpaper.enable = false;
}
