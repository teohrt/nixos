{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-walker.url = "github:nixos/nixpkgs/46db2e09e1d3f113a13c0d7b81e2f221c63b8ce9";
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

  outputs = inputs@{ nixpkgs, nixpkgs-unstable, nixpkgs-walker, home-manager, stylix, spicetify-nix, nixos-hardware, sops-nix, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
    pkgs-unstable = import nixpkgs-unstable { inherit system; config.allowUnfree = true; };
    pkgs-walker = nixpkgs-walker.legacyPackages.${system};

    # Import stylix theme config (nord)
    themeConfig = import ./modules/home/themes.nix { inherit pkgs; };

    # Base home modules shared by all machines
    baseHomeModules = [
      ./modules/home/core
      ./modules/home/optional/user-apps.nix
      ./modules/home/optional/desktop/hyprland.nix
      ./modules/home/optional/desktop/waybar.nix
      ./modules/home/optional/desktop/walker.nix
      ./modules/home/optional/desktop/wallpaper.nix
      ./modules/home/optional/desktop/hyprlock.nix
      ./modules/home/optional/desktop/hypridle.nix
      ./modules/home/optional/apps/alacritty.nix
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
      home-manager.extraSpecialArgs = { inherit pkgs-unstable pkgs-walker spicetify-nix; };
    };
  in
  {
    nixosConfigurations = {
      my-thinkpad = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit pkgs-walker; };
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
        specialArgs = { inherit pkgs-walker; };
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
