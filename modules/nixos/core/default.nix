{ pkgs, username, ... }:
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Build using all available cores
    max-jobs = "auto";
    # Pull pre-built binaries from nix-community cache (home-manager, stylix, etc.)
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    # Deduplicate identical files in the store
    auto-optimise-store = true;
  };

  programs = {
    # nh - modern nix CLI helper with better UX
    nh = {
      enable = true;
      flake = "/home/${username}/Dev/other/nixos";
      clean = {
        enable = true;
        extraArgs = "--keep-since 7d";
      };
    };

    git.prompt.enable = true;

    zsh = {
      enable = true;
      autosuggestions.enable = true;
      autosuggestions.highlightStyle = "fg=#888888";
      syntaxHighlighting = {
        enable = true;
        styles = {
          "path" = "underline";
          "path_prefix" = "underline";
        };
      };
    };
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 1;
    };

    # Quiet boot + faster kernel init
    kernelParams = [
      "quiet"
      "loglevel=3"
      "systemd.show_status=auto"
      "rd.udev.log_level=3"
      "nowatchdog"
    ];
    consoleLogLevel = 0;
    extraModprobeConfig = "blacklist iTCO_wdt";
  };

  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [
      "wheel"
      "video"
      "docker"
      "networkmanager"
    ]; # video: brightnessctl; docker: rootless docker; networkmanager: NM control
    packages = [ ];
    shell = pkgs.zsh;
  };

  nixpkgs.config.allowUnfree = true;

  environment.sessionVariables = {
    EDITOR = "nvim";
    SOPS_AGE_KEY_FILE = "/home/${username}/.config/sops/age/keys.txt";
  };
}
