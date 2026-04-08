# NixOS Config Repo

This is a NixOS configuration repository managed with flakes.

## Workflow

- This machine **is** the target system (Framework 16).
- Claude can run commands directly to debug, test, and validate changes.
- Deploy with: `sudo nixos-rebuild switch --flake .#framework-16`

## Debugging

- Claude can run diagnostic commands directly (`wpctl status`, `journalctl`, etc.)
- Edit config files, rebuild, and verify changes in the same session.

## Structure

- `flake.nix` — entry point, defines hosts
- `hosts/` — per-machine config; each host imports the modules it needs
- `modules/nixos/core/` — shared NixOS config loaded by all machines
- `modules/nixos/optional/` — opt-in NixOS modules (desktop, networking, docker, stylix, themes)
- `modules/home/core/` — shared home-manager base config
- `modules/home/optional/` — opt-in home-manager modules (desktop apps, per-app configs)
- `assets/` — wallpaper images and videos, organised by theme
- `docs/` — documentation (theming system, adding machines)
