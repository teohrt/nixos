# NixOS Config Repo

This is a NixOS configuration repository managed with flakes.

## Workflow

- Changes are made here locally, but **this is not the target system**.
- The operator (human) deploys changes to a **remote NixOS host** and reports back with outcomes.
- All testing and validation happens on the remote host — not on this local machine.

## Debugging

- When something breaks, the operator runs the relevant commands on the remote host and pastes errors here.
- Debugging consists entirely of iterating on the config files in this repo — reading, editing, and suggesting changes.
- Claude does **not** run commands or inspect the local filesystem to debug, since this local machine is not the deployment target.

## Structure

- `flake.nix` — entry point, defines hosts
- `hosts/` — per-machine config; each host imports the modules it needs
- `modules/nixos/core/` — shared NixOS config loaded by all machines
- `modules/nixos/optional/` — opt-in NixOS modules (desktop, networking, docker, stylix, themes)
- `modules/home/core/` — shared home-manager base config
- `modules/home/optional/` — opt-in home-manager modules (desktop apps, per-app configs)
- `assets/` — wallpaper images and videos, organised by theme
- `docs/` — documentation (theming system, adding machines)
