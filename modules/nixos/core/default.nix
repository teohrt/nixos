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
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0; # Hold Space during boot to show menu

  programs.git.prompt.enable = true;

  users.users.trace = {
    isNormalUser = true;
    description = "trace";
    extraGroups = [ "wheel" "video" "docker" ]; # video group allows brightnessctl without sudo; docker allows running docker without sudo
    packages = [];
  };

  nixpkgs.config.allowUnfree = true;

  environment.sessionVariables.EDITOR = "vim";

  environment.systemPackages = [ pkgs.satty ];

  xdg.mime.defaultApplications = {
    "image/png" = "satty.desktop";
    "image/jpeg" = "satty.desktop";
    "image/gif" = "satty.desktop";
    "image/webp" = "satty.desktop";
    "image/bmp" = "satty.desktop";
    "image/tiff" = "satty.desktop";
  };
}
