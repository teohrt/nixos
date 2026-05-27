{ pkgs, ... }:
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
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

  # nh - modern nix CLI helper with better UX
  programs.nh = {
    enable = true;
    flake = "/home/trace/Dev/other/nixos";
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d";
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 1;

  # Quiet boot + faster kernel init
  boot.kernelParams = [ "quiet" "loglevel=3" "systemd.show_status=auto" "rd.udev.log_level=3" "nowatchdog" ];
  boot.consoleLogLevel = 0;
  boot.extraModprobeConfig = "blacklist iTCO_wdt";

  programs.git.prompt.enable = true;

  users.users.trace = {
    isNormalUser = true;
    description = "trace";
    extraGroups = [ "wheel" "video" "docker" "networkmanager" ]; # video: brightnessctl; docker: rootless docker; networkmanager: NM control
    packages = [];
    shell = pkgs.zsh;
  };

  programs.zsh = {
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

  nixpkgs.config.allowUnfree = true;

  environment.sessionVariables.EDITOR = "nvim";
  environment.sessionVariables.SOPS_AGE_KEY_FILE = "/home/trace/.config/sops/age/keys.txt";
}
