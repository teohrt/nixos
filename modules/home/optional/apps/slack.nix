# Slack only ships a 512x512 icon; generate smaller sizes for the noctalia launcher
{ pkgs, ... }:
{
  home.packages = [
    (pkgs.slack.overrideAttrs (old: {
      postFixup = (old.postFixup or "") + ''
        for size in 16 24 32 48 64 128 256; do
          dir=$out/share/icons/hicolor/''${size}x''${size}/apps
          mkdir -p $dir
          ${pkgs.imagemagick}/bin/magick $out/share/icons/hicolor/512x512/apps/slack.png \
            -resize ''${size}x''${size} $dir/slack.png
        done
      '';
    }))
  ];
}
