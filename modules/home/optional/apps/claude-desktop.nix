{ claude-desktop, pkgs, ... }:
let
  claude-desktop-pkg = claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.default;
  claude-desktop-wrapped = pkgs.symlinkJoin {
    name = "claude-desktop";
    paths = [ claude-desktop-pkg ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/claude-desktop \
        --add-flags "--password-store=basic"
    '';
  };
in
{
  home.packages = [ claude-desktop-wrapped ];
}
