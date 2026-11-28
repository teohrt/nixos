{ config, pkgs, ... }:
{
  systemd.services.mount-zach-nas = {
    description = "Mount Zach's NAS' SMB share from sops secrets";
    after = [ "tailscaled.service" ];
    requires = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];

    path = [
      pkgs.cifs-utils
      pkgs.util-linux
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 2;
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /mnt/zach_nas";
      ExecStart = pkgs.writeShellScript "mount-smb" ''
        device=$(cat ${config.sops.secrets."zach_nas_smb_device".path})
        mount -t cifs "$device" /mnt/zach_nas \
          -o credentials=${config.sops.secrets."zach_nas_smb_credentials".path},uid=1000,gid=100
      '';
      ExecStop = "${pkgs.util-linux}/bin/umount /mnt/zach_nas";
    };

    unitConfig.StartLimitIntervalSec = 30;
    unitConfig.StartLimitBurst = 15;
  };
}
