# NixOS Config

Personal NixOS configuration managed with flakes and [home-manager](https://github.com/nix-community/home-manager).

## Hosts

- `framework-16` — Framework 16 laptop
- `my-thinkpad` — ThinkPad

## Deploying

```bash
sudo nixos-rebuild switch --flake .#framework-16
```

## Structure

```
flake.nix                         # entry point, defines hosts
hosts/
  framework-16/
  my-thinkpad/
modules/
  nixos/
    core/                         # shared NixOS config (all machines)
    optional/
      desktop.nix                 # Hyprland, SDDM, pipewire, bluetooth
      networking.nix              # iwd, systemd-networkd
      docker.nix
      system-apps.nix
  home/
    core/                         # shared home-manager config
    themes.nix                    # Stylix theme (Nord)
    optional/
      desktop/
        hyprland.nix              # window manager, keybindings, scripts
        waybar.nix                # status bar
        wallpaper.nix             # static + video wallpaper picker
        walker.nix                # app launcher
        hyprlock.nix              # lock screen
        hypridle.nix              # idle manager
      apps/
        alacritty.nix
        firefox.nix
        vscode.nix
        obsidian.nix
        spicetify.nix
      user-apps.nix               # CLI tools, wrapped packages
assets/                           # screensaver config
docs/
  new-machine.md
  theming.md
```

## Features

- **Hyprland** — tiling Wayland compositor
- **Wallpaper picker** (`Super+Shift+W`) — static wallpapers via swww, video wallpapers via mpvpaper
- **Voice input** (`Super+/`) — press to record, press again to transcribe with whisper-cpp
- **Screen recording** — via wf-recorder with waybar indicator
- **App launcher** — walker with dmenu mode for various pickers
- **Theming** — Stylix with Nord color scheme

## Docs

- [Adding a new machine](docs/new-machine.md)
- [Theming](docs/theming.md)
