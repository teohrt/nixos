{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-kitty.url = "github:nixos/nixpkgs/54b9582d13af461680f6d6fdae4ee138dfd60d23";  # kitty 0.46.2
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = inputs@{ nixpkgs, nixpkgs-unstable, nixpkgs-kitty, home-manager, stylix, spicetify-nix, nixos-hardware, sops-nix, noctalia, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
    pkgs-unstable = import nixpkgs-unstable { inherit system; config.allowUnfree = true; };
    pkgs-kitty = nixpkgs-kitty.legacyPackages.${system};

    # Import stylix theme config (nord)
    themeConfig = import ./modules/home/themes.nix { inherit pkgs; };

    # Base home modules shared by all machines
    baseHomeModules = [
      ./modules/home/core
      ./modules/home/optional/user-apps.nix
      ./modules/home/optional/desktop/hyprland.nix
      ./modules/home/optional/desktop/noctalia.nix
      ./modules/home/optional/desktop/hypridle.nix
      ./modules/home/optional/apps/kitty.nix
      ./modules/home/optional/apps/firefox.nix
      ./modules/home/optional/apps/vscode.nix
      ./modules/home/optional/apps/obsidian.nix
      ./modules/home/optional/apps/spicetify.nix
    ];

    # Per-machine overrides
    machineOverrides = {
      framework-16 = ({ lib, ... }: {
        wayland.windowManager.hyprland.settings.monitor = lib.mkForce ",preferred,auto,1.25";
      });
      thinkpad = { };
    };

    # Shared home-manager NixOS module config
    hmNixosModule = {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "nixos-hm-backup";
      home-manager.extraSpecialArgs = { inherit pkgs-unstable pkgs-kitty spicetify-nix noctalia; };
    };
  in
  {
    nixosConfigurations = {
      my-thinkpad = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { };
        modules = [
          ./hosts/my-thinkpad
          sops-nix.nixosModules.sops
          stylix.nixosModules.stylix
          { inherit (themeConfig) stylix; }
          home-manager.nixosModules.home-manager
          hmNixosModule
        ];
      };
      framework-16 = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { };
        modules = [
          ./hosts/framework-16
          nixos-hardware.nixosModules.framework-16-7040-amd
          sops-nix.nixosModules.sops
          stylix.nixosModules.stylix
          { inherit (themeConfig) stylix; }
          home-manager.nixosModules.home-manager
          hmNixosModule
        ];
      };
    };
  };
}
