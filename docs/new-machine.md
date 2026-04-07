# Adding a New Machine

## 1. Create the host directory

```
hosts/<hostname>/
  default.nix
  hardware.nix
```

## 2. Generate hardware config on the target machine

```bash
nixos-generate-config --show-hardware-config > hardware.nix
```

Paste the output into `hosts/<hostname>/hardware.nix`.

## 3. Write `hosts/<hostname>/default.nix`

Start from `hosts/my-thinkpad/default.nix` as a reference. At minimum:

```nix
{ ... }:
{
  imports = [
    ./hardware.nix
    ../../modules/nixos/core
    # add optional modules as needed:
    # ../../modules/nixos/optional/desktop.nix
    # ../../modules/nixos/optional/networking.nix
    # ../../modules/nixos/optional/docker.nix
    # ../../modules/nixos/optional/stylix.nix
    # ../../modules/nixos/optional/themes.nix
    # ../../modules/nixos/optional/system-apps.nix
  ];

  networking.hostName = "<hostname>";
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  system.stateVersion = "25.11"; # set to the NixOS version at install time, never change

  # home-manager config for this machine (omit if headless)
  home-manager.users.trace = {
    imports = [
      ../../modules/home/core
      # add optional home modules as needed
    ];
  };
}
```

## 4. Register the host in `flake.nix`

Add an entry to `nixosConfigurations`:

```nix
my-new-machine = nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit pkgs-walker; };
  modules = [
    ./hosts/my-new-machine
    stylix.nixosModules.stylix
    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "nixos-hm-backup";
      home-manager.extraSpecialArgs = { inherit pkgs-walker spicetify-nix; };
    }
  ];
};
```

## 5. Deploy

On the target machine:

```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

## Optional modules reference

| Module | What it enables |
|--------|----------------|
| `nixos/optional/desktop.nix` | Hyprland, SDDM, pipewire, bluetooth, printing, portals |
| `nixos/optional/networking.nix` | iwd (WiFi), systemd-networkd, systemd-resolved |
| `nixos/optional/docker.nix` | Docker (socket-activated) |
| `nixos/optional/stylix.nix` | Stylix theming (Nord default) |
| `nixos/optional/themes.nix` | Theme specialisations + sudo rules for switching |
| `nixos/optional/system-apps.nix` | System-wide packages |
| `home/optional/desktop/` | Hyprland, waybar, walker, wallpaper picker, hyprlock, hypridle |
| `home/optional/apps/` | Per-app configs (git, alacritty, firefox, vscode, obsidian, spicetify) |
| `home/optional/user-apps.nix` | User-profile packages |
