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

- `flake.nix` — entry point, defines hosts and home-manager configs
- `nixos/` — NixOS system-level configuration modules
- `home-manager/` — user-level home-manager modules
