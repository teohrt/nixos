{ lib, ... }:

# mpvpaper handles wallpaper display and is launched via Hyprland exec-once.
# hyprpaper is disabled — it only supports static images, not video.
# Stylix still uses its static image (in stylix.nix) for color scheme generation,
# which is separate from what's displayed on screen.
{
  stylix.targets.hyprpaper.enable = false;
  services.hyprpaper.enable = lib.mkForce false;
}
