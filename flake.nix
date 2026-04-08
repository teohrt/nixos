{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
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
  };

  outputs = inputs@{ nixpkgs, nixpkgs-walker, home-manager, stylix, spicetify-nix, nixos-hardware, ... }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    pkgs-walker = nixpkgs-walker.legacyPackages.${system};

    # Import theme definitions
    themesDef = import ./modules/home/themes.nix { inherit pkgs; };

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
      thinkpad = { };  # No overrides for thinkpad
    };

    # Shared home-manager NixOS module config
    hmNixosModule = {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "nixos-hm-backup";
      home-manager.extraSpecialArgs = { inherit pkgs-walker spicetify-nix; };
      home-manager.sharedModules = [
        stylix.homeManagerModules.stylix
        {
          stylix = themesDef.stylixBase // {
            image = themesDef.themes.nord.image;
            base16Scheme = themesDef.themes.nord.scheme;
          };
        }
      ];
    };

    # Build a standalone home-manager config for a machine + theme
    mkHomeConfig = machine: theme: home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit pkgs-walker spicetify-nix; };
      modules = [
        stylix.homeManagerModules.stylix
        {
          home.username = "trace";
          home.homeDirectory = "/home/trace";
          home.stateVersion = "25.11";
          programs.home-manager.enable = true;
          stylix = themesDef.stylixBase // {
            image = themesDef.themes.${theme}.image;
            base16Scheme = themesDef.themes.${theme}.scheme;
          };
        }
        machineOverrides.${machine}
      ] ++ baseHomeModules;
    };

    # Generate homeConfigurations for all machine/theme combinations
    machines = [ "framework-16" "thinkpad" ];
    themeNames = builtins.attrNames themesDef.themes;
  in
  {
    nixosConfigurations = {
      my-thinkpad = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit pkgs-walker; };
        modules = [
          ./hosts/my-thinkpad
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
          home-manager.nixosModules.home-manager
          hmNixosModule
        ];
      };
    };

    homeConfigurations = builtins.listToAttrs (
      builtins.concatMap (machine:
        map (theme: {
          name = "trace@${machine}-${theme}";
          value = mkHomeConfig machine theme;
        }) themeNames
      ) machines
    );
  };
}
