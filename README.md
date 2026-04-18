# NixOS Config

> [!WARNING]
> This is my personal NixOS configuration and is provided for example purposes only. It is tailored to my specific hardware, workflow, and preferences. Use at your own risk — copying this configuration directly is unlikely to work without significant adaptation.

Personal [NixOS](https://nixos.org/) configuration for multiple machines using [Nix flakes](https://nixos.wiki/wiki/Flakes), [Home Manager](https://nix-community.github.io/home-manager/), and declarative system management.


## Structure

Each host imports from a shared module system:

- **`modules/nixos/core/`** — Base NixOS config shared by all machines (nix settings, bootloader, user, shell)
- **`modules/nixos/optional/`** — Opt-in system modules (desktop, networking, docker, steam, sops)
- **`modules/home/core/`** — Base home-manager config (notifications, power menu, screensaver)
- **`modules/home/optional/`** — Opt-in user modules (hyprland, waybar, apps, etc.)

Hosts live in `hosts/<hostname>/` and pick which optional modules to include. See [Adding a new machine](docs/new-machine.md) for the full module reference.


## Docs

- [Adding a new machine](docs/new-machine.md)
- [Secrets management](docs/secrets.md)
- [Theming](docs/theming.md)
