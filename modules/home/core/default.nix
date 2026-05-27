{ config, pkgs, lib, ... }:
{
  home.username = "trace";
  home.homeDirectory = "/home/trace";

  programs.btop.enable = true;
  # Disabled - .zshrc managed via dotfiles repo stow
  programs.zsh.enable = false;

  # Darken Nautilus background so text stays readable across light and dark themes.
  # shade() is a GTK CSS function: values < 1 darken, > 1 lighten.
  stylix.targets.gtk.extraCss = ''
    .nautilus-window {
      background-color: shade(@window_bg_color, 0.75);
    }
  '';

  dconf.settings = {
    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
    };
  };

  # Register global MCP servers for Claude Code (--scope user).
  # Available in every Claude Code session regardless of directory.
  # Uses activation script because ~/.claude.json is actively managed by Claude Code.
  home.activation.claude-mcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.claude-code}/bin/claude mcp add exa --scope user -- \
      sh -c 'export EXA_API_KEY=$(sops -d --extract '"'"'["exa_api_key"]'"'"' /home/trace/Dev/other/nixos/secrets/secrets.yaml) && npx -y exa-mcp-server' \
      || true
  '';

  home.stateVersion = "25.11";
}
