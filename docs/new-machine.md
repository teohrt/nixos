# Adding a New Machine

## 1. Create the host directory

```
hosts/<hostname>/
  default.nix
  hardware.nix
```

## 2. Set up secrets

Generate an age key for the new host and add it to the secrets file so it can decrypt on first deploy. Follow the [secrets management guide](secrets.md#adding-a-new-host).

## 3. Generate hardware config on the target machine

```bash
nixos-generate-config --show-hardware-config > hardware.nix
```

Paste the output into `hosts/<hostname>/hardware.nix`.

## 4. Check for hardware-specific modules

The flake includes [nixos-hardware](https://github.com/NixOS/nixos-hardware) for vendor-specific fixes. Check if your hardware has a module:

```bash
# Browse available modules
ls $(nix build nixos-hardware --print-path --no-link)/nixos
```

Common examples:
- `framework-13-7040-amd`
- `framework-16-7040-amd`
- `lenovo-thinkpad-t480`
- `dell-xps-15-9500`

## 5. Write `hosts/<hostname>/default.nix`

Use `hosts/framework-16/default.nix` as a reference:

```nix
{ pkgs, lib, ... }:
{
  imports = [
    ./hardware.nix
    ../../modules/nixos/core
    ../../modules/nixos/optional/desktop.nix
    ../../modules/nixos/optional/networking.nix
    ../../modules/nixos/optional/docker.nix
    ../../modules/nixos/optional/system-apps.nix
  ];

  networking.hostName = "<hostname>";
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  home-manager.users.trace = {
    imports = [
      ../../modules/home/core
      ../../modules/home/optional/user-apps.nix
      ../../modules/home/optional/desktop/hyprland.nix
      ../../modules/home/optional/desktop/waybar.nix
      ../../modules/home/optional/desktop/walker.nix
      ../../modules/home/optional/desktop/wallpaper.nix
      ../../modules/home/optional/desktop/hyprlock.nix
      ../../modules/home/optional/desktop/hypridle.nix
      ../../modules/home/optional/apps/alacritty.nix
      ../../modules/home/optional/apps/firefox.nix
      ../../modules/home/optional/apps/vscode.nix
      ../../modules/home/optional/apps/obsidian.nix
      ../../modules/home/optional/apps/spicetify.nix
    ];

    # Override monitor scaling if needed (default is 1.2x)
    # wayland.windowManager.hyprland.settings.monitor = lib.mkForce ",preferred,auto,1.25";
  };

  system.stateVersion = "25.11"; # set to NixOS version at install time, never change
}
```

## 6. Register the host in `flake.nix`

Add an entry to `nixosConfigurations`:

```nix
my-new-machine = nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit pkgs-walker; };
  modules = [
    ./hosts/my-new-machine
    # Add hardware module if available:
    # nixos-hardware.nixosModules.framework-16-7040-amd
    stylix.nixosModules.stylix
    { inherit (themeConfig) stylix; }
    home-manager.nixosModules.home-manager
    hmNixosModule
  ];
};
```

## 7. Deploy

On the target machine:

```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

## Optional modules reference

### NixOS modules (`modules/nixos/optional/`)

| Module | What it enables |
|--------|----------------|
| `desktop.nix` | Hyprland, SDDM, PipeWire, Bluetooth, printing, XDG portals |
| `networking.nix` | iwd (WiFi), systemd-networkd, systemd-resolved |
| `docker.nix` | Docker (socket-activated) |
| `system-apps.nix` | System-wide packages (vim, git, etc.) |
| `sops.nix` | Secrets management with age encryption ([setup guide](secrets.md)) |
| `steam.nix` | Steam, GameMode, 32-bit graphics |

### Home modules (`modules/home/optional/`)

| Module | What it enables |
|--------|----------------|
| `desktop/hyprland.nix` | Hyprland compositor, keybindings, window rules |
| `desktop/waybar.nix` | Status bar |
| `desktop/walker.nix` | Application launcher |
| `desktop/wallpaper.nix` | swww wallpaper daemon, wallpaper picker |
| `desktop/hyprlock.nix` | Lock screen |
| `desktop/hypridle.nix` | Idle management (screensaver, lock, suspend timers) |
| `apps/alacritty.nix` | Terminal emulator |
| `apps/firefox.nix` | Browser |
| `apps/vscode.nix` | Code editor |
| `apps/obsidian.nix` | Note-taking |
| `apps/spicetify.nix` | Spotify theming |
| `user-apps.nix` | User-profile packages |
| `ssh.nix` | SSH config with GitHub keys (requires [sops](secrets.md)) |

## Hardware-specific configuration

For hardware that needs special handling (audio quirks, firmware, scaling), add configuration directly to the host's `default.nix`. See `hosts/framework-16/default.nix` for examples:

- WirePlumber rules for audio profile selection
- Bluetooth auto-switching
- Zoom XWayland scaling overlay
- Monitor scaling overrides
