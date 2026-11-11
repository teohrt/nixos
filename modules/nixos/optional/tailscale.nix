# Tailscale mesh VPN for secure access between machines.
#
# One-time setup:
#   1. Create a Tailscale account at https://login.tailscale.com
#   2. Generate a reusable auth key at https://login.tailscale.com/admin/settings/keys
#      (enable "Reusable" and optionally disable expiration)
#   3. Add the key to sops secrets:
#        sops secrets/secrets.yaml
#        # tailscale_auth_key: tskey-auth-...
#   4. Rebuild both machines — they'll join the tailnet automatically
#
# After both machines are on the tailnet:
#   ssh thinkpad              # from framework
#   ssh framework             # from thinkpad
#   ssh thinkpad -t tmux a    # attach to tmux on thinkpad
#
# Phone: install Tailscale app, join the same tailnet, SSH with any client.
{ config, ... }:
{
  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."tailscale_auth_key".path;
  };

  networking.firewall = {
    trustedInterfaces = [ config.services.tailscale.interfaceName ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  # SSH server — only reachable over the tailnet (openFirewall = false keeps
  # port 22 closed on LAN/WAN interfaces; trustedInterfaces above allows it
  # through on tailscale0).
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
