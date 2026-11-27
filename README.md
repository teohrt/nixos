# NixOS Config

> [!WARNING]
> This is my personal NixOS configuration and is provided for example purposes only. It is tailored to my specific hardware, workflow, and preferences. Use at your own risk — copying this configuration directly is unlikely to work without significant adaptation.

Personal [NixOS](https://nixos.org/) configuration for multiple machines using [Nix flakes](https://nixos.wiki/wiki/Flakes), [Home Manager](https://nix-community.github.io/home-manager/), and declarative system management.


## Structure

Hosts are organized by type, with shared modules managed through the flake's host builders:

```
hosts/
  workstations/     # Desktop machines — mkWorkstationHost
    framework-16/
    my-thinkpad/
  homelab/          # Servers — mkHomelabHost
    alpha/
```

Modules are layered:

- **`modules/nixos/core/`** — Base NixOS config shared by all machines (nix settings, bootloader, user, shell)
- **`modules/nixos/optional/`** — Opt-in system modules; `workstation.nix` bundles the desktop set
- **`modules/home/core/`** — Base home-manager config (notifications, power menu, screensaver)
- **`modules/home/optional/`** — Opt-in user modules; `workstation.nix` bundles desktop apps

The flake provides three host builders: `mkHost` (base — core, docker, sops, tailscale), `mkWorkstationHost` (adds desktop, theming, GUI apps), and `mkHomelabHost` (adds SSH only). See [Adding a host](docs/adding-a-host.md) for the full module reference.


## Docs

- [Adding a host](docs/adding-a-host.md)
- [Adding a homelab node](docs/adding-a-homelab-node.md)
- [Secrets management](docs/secrets.md)
- [Theming](docs/theming.md)
