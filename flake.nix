{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-walker.url = "github:nixos/nixpkgs/46db2e09e1d3f113a13c0d7b81e2f221c63b8ce9";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with
      # the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs.
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
    jolt.url = "github:jordond/jolt";
  };

  outputs = inputs@{ nixpkgs, nixpkgs-walker, home-manager, stylix, spicetify-nix, jolt, ... }:
  let
    system = "x86_64-linux";
    pkgs-walker = nixpkgs-walker.legacyPackages.${system};
    pkgs-jolt = jolt.packages.${system}.default;
  in
  {
    nixosConfigurations = {
      my-nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit pkgs-walker pkgs-jolt; };
        modules = [
          ./nixos/configuration.nix
          stylix.nixosModules.stylix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "nixos-hm-backup";

            home-manager.extraSpecialArgs = { inherit pkgs-walker pkgs-jolt spicetify-nix; };
            home-manager.users.trace = import ./home-manager/home.nix;
          }
        ];
      };
    };
  };
}
