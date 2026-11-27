{
  # Darken Nautilus background so text stays readable across light and dark themes.
  # shade() is a GTK CSS function: values < 1 darken, > 1 lighten.
  stylix.targets.gtk.extraCss = ''
    .nautilus-window {
      background-color: shade(@window_bg_color, 0.75);
    }
  '';
}
