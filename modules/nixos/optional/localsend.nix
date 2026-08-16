# LocalSend: open firewall port for LAN device discovery and file transfer.
_: {
  networking.firewall = {
    allowedTCPPorts = [ 53317 ];
    allowedUDPPorts = [ 53317 ];
  };
}
