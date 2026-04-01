{ ... }:

# mpvpaper handles wallpaper display and is launched via Hyprland exec-once.
# hyprpaper is disabled — it only supports static images, not video.
# stylix still uses a static image (in stylix.nix) for color scheme generation,
# which is separate from what's displayed on screen.
{
  # Disable stylix's hyprpaper target so it doesn't conflict with mpvpaper.
  # Stylix still uses its static image for color scheme generation — it just
  # won't manage the wallpaper display.
  stylix.targets.hyprpaper.enable = false;
}
