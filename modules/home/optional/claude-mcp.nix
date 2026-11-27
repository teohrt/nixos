{
  pkgs,
  lib,
  username,
  ...
}:
{
  # Register global MCP servers for Claude Code (--scope user).
  # Available in every Claude Code session regardless of directory.
  # Uses activation script because ~/.claude.json is actively managed by Claude Code.
  home.activation.claude-mcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.claude-code}/bin/claude mcp add exa --scope user -- \
      sh -c 'export EXA_API_KEY=$(sops -d --extract '"'"'["exa_api_key"]'"'"' /home/${username}/Dev/other/nixos/secrets/secrets.yaml) && npx -y exa-mcp-server' \
      || true
  '';
}
