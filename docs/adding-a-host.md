# Adding a New Machine

## 1. Create the host directory

Hosts are organized by type:

```
hosts/
  workstations/<hostname>/    # for mkWorkstationHost
    default.nix
    hardware.nix
  homelab/<hostname>/         # for mkHomelabHost
    default.nix
    hardware.nix
```

## 2. Set up secrets

Generate an age key for the new host and add it to the secrets file so it can decrypt on first deploy. Follow the [secrets management guide](secrets.md#adding-a-new-host).

## 3. Generate hardware config on the target machine

```bash
nixos-generate-config --show-hardware-config > hardware.nix
```

Paste the output into the host's `hardware.nix`.

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

## 5. Write the host's `default.nix`

Core NixOS modules, docker, sops, tailscale, and home-manager core are all provided by the flake's host builders — you don't need to import them. The host's `default.nix` only needs hardware-specific config.

**Workstation** (use `hosts/workstations/framework-16/default.nix` as a reference):

```nix
{ pkgs, ... }:
{
  imports = [ ./hardware.nix ];

  networking.hostName = "<hostname>";

  # Hardware-specific config goes here (audio fixes, GPU drivers, etc.)

  system.stateVersion = "26.05"; # set to NixOS version at install time, never change
}
```

**Homelab** (use `hosts/homelab/alpha/default.nix` as a reference):

```nix
{ pkgs, ... }:
{
  imports = [ ./hardware.nix ];

  networking.hostName = "<hostname>";

  # Server-specific config goes here (LXQt, greetd, services, etc.)

  system.stateVersion = "26.05";
}
```

## 6. Register the host in `flake.nix`

Add an entry to `nixosConfigurations` using the appropriate builder:

```nix
# Workstation
my-new-machine = mkWorkstationHost ./hosts/workstations/my-new-machine [
  # Add hardware module if available:
  # nixos-hardware.nixosModules.framework-16-7040-amd
];

# Homelab
my-new-server = mkHomelabHost ./hosts/homelab/my-new-server [ ];
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
| `apps/kitty.nix` | Terminal emulator |
| `apps/firefox.nix` | Browser |
| `apps/vscode.nix` | Code editor |
| `apps/obsidian.nix` | Note-taking |
| `apps/spicetify.nix` | Spotify theming |
| `user-apps.nix` | User-profile packages |
| `ssh.nix` | SSH config with GitHub keys (requires [sops](secrets.md)) |

## Hardware-specific configuration

For hardware that needs special handling (audio quirks, firmware, scaling), add configuration directly to the host's `default.nix`. See `hosts/workstations/framework-16/default.nix` for examples:

- WirePlumber rules for audio profile selection
- Bluetooth auto-switching
- Zoom XWayland scaling overlay
- Monitor scaling overrides
