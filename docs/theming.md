# Theming

Theming uses [Stylix](https://github.com/danth/stylix) for declarative cross-app color generation, combined with NixOS specialisations for runtime switching between color schemes.

## How it works

### Color schemes

Three themes are defined:

| Theme | Specialisation | Color scheme |
|-------|---------------|-------------|
| Nord | *(base system)* | `nord.yaml` |
| Gruvbox | `gruvbox` | `gruvbox-dark-hard.yaml` |
| Eris | `eris` | `eris.yaml` |

The base system always uses Nord. The other themes are NixOS *specialisations* — fully pre-built system variants that override `stylix.image` and `stylix.base16Scheme`. All three are built during `nixos-rebuild switch`.

### Switching themes

Press `Super+Shift+W` to open the wallpaper picker. Selecting a wallpaper:

1. Activates the NixOS specialisation for that theme via `sudo switch-to-configuration switch`
2. Sets the wallpaper (static via `hyprpaper`, animated via `mpvpaper`)
3. Restarts `waybar`, `mako`, `walker`, and kills `nautilus` so they pick up the new Stylix-generated configs

The sudo rules for specialisation switching are in `modules/nixos/optional/themes.nix`.

### Wallpapers

Wallpapers are defined in `modules/home/optional/desktop/wallpaper.nix`. Each theme has a list of wallpapers:

```nix
{ name = "Mountain"; path = ../../../../assets/nord/mountain.png; animated = false; }
{ name = "Black Hole"; path = ../../../../assets/nord/black_hole.mp4; animated = true; }
```

- `animated = false` → displayed via `hyprpaper`
- `animated = true` → displayed via `mpvpaper` (supports MP4/GIF)

Assets live in `assets/<theme>/`.

## Adding a new wallpaper

1. Drop the file into `assets/<theme>/`
2. Add an entry to the theme's `wallpapers` list in `modules/home/optional/desktop/wallpaper.nix`
3. Rebuild

## Adding a new theme

1. Add a base16 scheme file to `assets/<theme>/` (or reference one from `pkgs.base16-schemes`)
2. Add a specialisation in `modules/nixos/optional/themes.nix`:
   ```nix
   mytheme.configuration = {
     stylix.image = lib.mkForce ../../../assets/mytheme/wallpaper.png;
     stylix.base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/mytheme.yaml";
   };
   ```
3. Add a sudo rule for the new specialisation in the same file
4. Add the theme and its wallpapers to `modules/home/optional/desktop/wallpaper.nix`
5. Rebuild
