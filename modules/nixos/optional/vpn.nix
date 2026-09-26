# ExpressVPN via OpenVPN manual configuration.
#
# The official nixpkgs expressvpn package (services.expressvpn) has a broken
# daemon due to FHS/resolv.conf issues and loses activation on every reboot.
# OpenVPN with ExpressVPN's manual .ovpn files is the reliable alternative.
#
# One-time setup (commit to repo — no per-machine steps after):
#   1. Go to expressvpn.com/setup#manual, select OpenVPN, pick a server location
#   2. Download the .ovpn file and place it at modules/nixos/optional/expressvpn.ovpn
#   3. Add credentials to secrets.yaml (username/password shown on the same page):
#        sops secrets/secrets.yaml
#        # expressvpn_credentials: |
#        #   <username>
#        #   <password>
#   Then commit both. Every machine gets them on the next rebuild.
#
# Usage:
#   systemctl start openvpn-expressvpn   # connect
#   systemctl stop openvpn-expressvpn    # disconnect
#
# To swap servers: replace expressvpn.ovpn and rebuild.
{ pkgs, ... }:
{
  # OpenVPN plugin for NetworkManager — lets Noctalia's network widget and
  # nmcli import/toggle VPN connections alongside normal network management.
  networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];

  # Declarative OpenVPN service, off by default (start manually when needed).
  # The .ovpn file has no personal data so it's committed directly to the repo.
  # Credentials are sops-managed so they never appear in the Nix store.
  services.openvpn.servers.expressvpn = {
    autoStart = false;
    updateResolvConf = true;
    config = "config ${./expressvpn.ovpn}";
    authUserPass = "/run/secrets/expressvpn_credentials";
  };
}
