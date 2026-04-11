# Theming

Theming uses [Stylix](https://github.com/danth/stylix) for declarative cross-app color generation. The theme is defined in `modules/home/themes.nix`.

## How it works

### Color scheme

The system uses Nord as the base16 color scheme. Stylix automatically generates consistent colors across GTK apps, terminals, waybar, and other applications.

Configuration in `modules/home/themes.nix`:
- `base16Scheme` — color palette (Nord)
- `polarity` — dark or light mode
- `opacity` — transparency levels for terminals, apps, popups
- `fonts` — system-wide font (JetBrains Mono Nerd Font)
- `cursor` — cursor theme (Bibata)

### Wallpapers

Wallpapers are managed separately from theming using [swww](https://github.com/LGFae/swww), which provides smooth animated transitions.

Press `Super+Shift+W` to open the wallpaper picker. Selecting a wallpaper triggers an animated transition effect.

Wallpapers are defined in `modules/home/optional/desktop/wallpaper.nix` and fetched from URLs at build time:

```nix
{
  name = "Dark - Black Hole";
  path = pkgs.fetchurl {
    url = "https://w.wallhaven.cc/full/po/wallhaven-pojl63.png";
    sha256 = "162yh1ppaizbmhc1vnnypjfjiyiyyfyj49hdbxhfzvps1pc94j8g";
  };
}
```

## Adding a new wallpaper

1. Find the image URL
2. Get the hash: `nix-prefetch-url <url>`
3. Add an entry to the `wallpapers` list in `modules/home/optional/desktop/wallpaper.nix`:
   ```nix
   {
     name = "My Wallpaper";
     path = pkgs.fetchurl {
       url = "https://example.com/wallpaper.png";
       sha256 = "<hash from nix-prefetch-url>";
     };
   }
   ```
4. Rebuild

## Changing the color scheme

Edit `modules/home/themes.nix`:

```nix
base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
```

Available schemes are in `pkgs.base16-schemes`. Common options:
- `nord.yaml`
- `gruvbox-dark-hard.yaml`
- `catppuccin-mocha.yaml`
- `dracula.yaml`
- `tokyo-night-dark.yaml`

After changing, rebuild to apply the new colors system-wide.
