{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-walker.url = "github:nixos/nixpkgs/46db2e09e1d3f113a13c0d7b81e2f221c63b8ce9";
    nixpkgs-kitty.url = "github:nixos/nixpkgs/54b9582d13af461680f6d6fdae4ee138dfd60d23"; # kitty 0.46.2
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
    claude-desktop.url = "github:patrickjaja/claude-desktop-bin";
    hyprland.url = "github:hyprwm/Hyprland";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      nixpkgs-unstable,
      nixpkgs-walker,
      nixpkgs-kitty,
      home-manager,
      stylix,
      spicetify-nix,
      nixos-hardware,
      sops-nix,
      noctalia,
      claude-desktop,
      hyprland,
      git-hooks,
      ...
    }:
    let
      system = "x86_64-linux";
      username = "trace";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-walker = nixpkgs-walker.legacyPackages.${system};
      pkgs-kitty = nixpkgs-kitty.legacyPackages.${system};

      # Import stylix theme config (nord)
      themeConfig = import ./modules/home/themes.nix { inherit pkgs; };

      # Shared home-manager NixOS module config
      hmNixosModule = {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "nixos-hm-backup";
          users.${username}.imports = [
            ./modules/home/core
            ./modules/home/optional/user-apps.nix
            ./modules/home/optional/desktop/hyprland.nix
            ./modules/home/optional/desktop/noctalia.nix
            ./modules/home/optional/desktop/walker.nix
            ./modules/home/optional/desktop/hypridle.nix
            ./modules/home/optional/apps/kitty.nix
            ./modules/home/optional/apps/firefox.nix
            ./modules/home/optional/apps/vscode.nix
            ./modules/home/optional/apps/obsidian.nix
            ./modules/home/optional/apps/spicetify.nix
            ./modules/home/optional/ssh.nix
          ];
          extraSpecialArgs = {
            inherit
              pkgs-unstable
              pkgs-walker
              pkgs-kitty
              spicetify-nix
              noctalia
              username
              ;
          };
        };
      };

      # Build a NixOS system config from a host path + optional extra modules
      mkHost =
        hostPath: extraModules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs username; };
          modules = [
            hostPath
            sops-nix.nixosModules.sops
            stylix.nixosModules.stylix
            { inherit (themeConfig) stylix; }
            home-manager.nixosModules.home-manager
            hmNixosModule
            { environment.systemPackages = [ claude-desktop.packages.${system}.default ]; }
          ]
          ++ extraModules;
        };
    in
    {
      nixosConfigurations = {
        my-thinkpad = mkHost ./hosts/my-thinkpad [ ];
        framework-16 = mkHost ./hosts/framework-16 [
          nixos-hardware.nixosModules.framework-16-7040-amd # AMD-specific kernel, firmware, and power tuning
        ];
      };

      checks.${system} = {
        pre-commit-check = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt-rfc-style.enable = true;
            statix.enable = true;
          };
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        inherit (inputs.self.checks.${system}.pre-commit-check) shellHook;
        buildInputs = inputs.self.checks.${system}.pre-commit-check.enabledPackages;
      };
    };
}
