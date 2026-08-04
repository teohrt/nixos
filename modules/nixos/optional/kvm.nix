{ pkgs, username, ... }:
{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
    };
  };

  # libvirt's default NAT network doesn't auto-start after boot; virt-manager
  # throws "network 'default' is not active" without this.
  systemd.services.libvirt-network-default = {
    description = "libvirt default network";
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    script = ''
      if ! ${pkgs.libvirt}/bin/virsh net-info default 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "^Active:.*yes"; then
        ${pkgs.libvirt}/bin/virsh net-start default
      fi
    '';
  };

  programs.virt-manager.enable = true;

  users.users.${username}.extraGroups = [ "libvirtd" ];
}
