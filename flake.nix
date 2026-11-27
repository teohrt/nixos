{
  description = "NixOS configuration";

  inputs = {
    # Base
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Theming
    stylix = {
      url = "github:danth/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Workstation apps
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-desktop = {
      url = "github:GoByeBye/claude-desktop-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    herdr-nix = {
      url = "github:herdrdev/herdr-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    workmux.url = "github:raine/workmux";

    # Dev tooling
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      sops-nix,
      nixos-hardware,
      stylix,
      spicetify-nix,
      claude-desktop,
      noctalia,
      herdr-nix,
      workmux,
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

      themeConfig = import ./modules/home/themes.nix { inherit pkgs; };

      # --- Host builders ---
      #
      # mkHost: base builder — core NixOS, docker, sops, tailscale, home-manager
      # mkWorkstationHost: desktop environment, theming, GUI apps
      # mkHomelabHost: headless server, SSH only

      mkHost =
        hostPath:
        {
          extraModules ? [ ],
          hmImports ? [ ],
          hmExtraSpecialArgs ? { },
          nixosExtraModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs pkgs-unstable username; };
          modules = [
            hostPath
            { nixpkgs.hostPlatform = system; }
            ./modules/nixos/core
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "nixos-hm-backup";
                users.${username}.imports = [ ./modules/home/core ] ++ hmImports;
                extraSpecialArgs = {
                  inherit pkgs-unstable username;
                }
                // hmExtraSpecialArgs;
              };
            }
          ]
          ++ nixosExtraModules
          ++ extraModules;
        };

      mkWorkstationHost =
        hostPath: extraModules:
        mkHost hostPath {
          inherit extraModules;
          nixosExtraModules = [
            stylix.nixosModules.stylix
            { inherit (themeConfig) stylix; }
            ./modules/nixos/optional/workstation.nix
          ];
          hmImports = [ ./modules/home/optional/workstation.nix ];
          hmExtraSpecialArgs = {
            inherit
              spicetify-nix
              claude-desktop
              noctalia
              herdr-nix
              ;
          };
        };

      mkHomelabHost =
        hostPath: extraModules:
        mkHost hostPath {
          inherit extraModules;
          hmImports = [ ./modules/home/optional/ssh.nix ];
        };
    in
    {
      # --- Hosts ---

      nixosConfigurations = {
        # Workstations
        framework-16 = mkWorkstationHost ./hosts/workstations/framework-16 [
          nixos-hardware.nixosModules.framework-16-7040-amd
        ];
        my-thinkpad = mkWorkstationHost ./hosts/workstations/my-thinkpad [ ];

        # Homelab
        alpha = mkHomelabHost ./hosts/homelab/alpha [ ];
      };

      # --- Dev tooling ---

      checks.${system}.pre-commit-check = git-hooks.lib.${system}.run {
        src = ./.;
        package = pkgs.prek;
        hooks = {
          nixfmt.enable = true;
          statix.enable = true;
          selene.enable = true;
          nix-build-check = {
            enable = true;
            name = "nix-build-check";
            entry = toString (
              pkgs.writeShellScript "nix-build-check" ''
                failed=0
                for host in framework-16 my-thinkpad; do
                  echo "Evaluating $host..."
                  if ! nix build .#nixosConfigurations.$host.config.system.build.toplevel --dry-run 2>&1; then
                    echo "FAIL: $host"
                    failed=1
                  fi
                done
                exit $failed
              ''
            );
            files = "\\.nix$";
            pass_filenames = false;
          };
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = inputs.self.checks.${system}.pre-commit-check.enabledPackages ++ [
          pkgs.lua-language-server
          pkgs.selene
        ];
        shellHook = ''
          ${inputs.self.checks.${system}.pre-commit-check.shellHook}

          cat > modules/home/optional/desktop/hyprland/.luarc.json <<'LUARC'
          {
            "runtime": { "version": "Lua 5.4" },
            "workspace": {
              "library": ["${pkgs.hyprland}/share/hypr/stubs"],
              "checkThirdParty": false
            },
            "diagnostics": {
              "globals": ["hl"]
            }
          }
          LUARC
        '';
      };
    };
}
