{
  config,
  pkgs,
  lib,
  username,
  ...
}:
{
  home = {
    inherit username;
    homeDirectory = "/home/${username}";

    # Register global MCP servers for Claude Code (--scope user).
    # Available in every Claude Code session regardless of directory.
    # Uses activation script because ~/.claude.json is actively managed by Claude Code.
    activation.claude-mcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.claude-code}/bin/claude mcp add exa --scope user -- \
        sh -c 'export EXA_API_KEY=$(sops -d --extract '"'"'["exa_api_key"]'"'"' /home/${username}/Dev/other/nixos/secrets/secrets.yaml) && npx -y exa-mcp-server' \
        || true
    '';

    stateVersion = "25.11";
  };

  programs.btop.enable = true;
  # Disabled - .zshrc managed via dotfiles repo stow
  programs.zsh.enable = false;

  dconf.settings = {
    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
    };
  };
}
