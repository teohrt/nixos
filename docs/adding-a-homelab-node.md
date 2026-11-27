# Adding a Homelab Node

Step-by-step guide for installing NixOS on a homelab mini PC using the minimal ISO and a network KVM for console access. The node runs LXQt as a lightweight desktop with auto-login via greetd — accessible through the KVM, while day-to-day management happens over SSH.

## Prerequisites

- Mini PC with network KVM attached
- USB flash drive (1 GB+)
- Another machine on the same network (for SSH after install)
- This flake repo cloned somewhere you can push from

## 1. Flash the Minimal ISO

Download the latest **NixOS minimal ISO** (not the graphical one):

```
https://nixos.org/download/#nixos-iso → Minimal ISO Image (64-bit Intel/AMD)
```

Flash it to USB:

```bash
# Find the USB device
lsblk

# Flash (replace /dev/sdX with your USB device)
sudo dd if=nixos-minimal-*.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

## 2. Boot from USB via Network KVM

1. Plug the USB into the mini PC
2. Connect to the network KVM from your browser
3. Power on the mini PC and enter the BIOS (usually `F2` or `Del`)
4. Set USB as the first boot device
5. Save and exit — the NixOS installer will boot to a root shell

## 3. Connect to the Network

The minimal ISO starts with DHCP on wired interfaces by default. Verify connectivity:

```bash
ip addr    # confirm an IP was assigned on the ethernet interface
ping nixos.org
```

If you need to set a static IP:

```bash
ip addr add 192.168.1.X/24 dev eth0
ip route add default via 192.168.1.1
echo "nameserver 1.1.1.1" > /etc/resolv.conf
```

## 4. (Optional) Enable SSH for a More Comfortable Install

Working through the KVM is fine, but SSH is easier for copy-pasting. From the KVM console:

```bash
# Set a password for the nixos user so you can SSH in
passwd

# SSH is already running on the minimal ISO
ip addr   # note the IP
```

Then from your other machine:

```bash
ssh nixos@<mini-pc-ip>
sudo -i
```

## 5. Partition the Disk

Identify the target disk:

```bash
lsblk
```

This example uses a single NVMe drive (`/dev/nvme0n1`) with a simple GPT layout: EFI + root. Adjust for your hardware.

```bash
parted /dev/nvme0n1 -- mklabel gpt

# 512 MB EFI system partition
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
parted /dev/nvme0n1 -- set 1 esp on

# Rest of disk for root
parted /dev/nvme0n1 -- mkpart root ext4 512MiB 100%
```

Format:

```bash
mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1
mkfs.ext4 -L nixos /dev/nvme0n1p2
```

Mount:

```bash
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/BOOT /mnt/boot
```

## 6. Generate Hardware Config

```bash
nixos-generate-config --root /mnt
```

This creates `/mnt/etc/nixos/hardware-configuration.nix`. Copy its contents — you'll need it for the host directory in this repo:

```bash
cat /mnt/etc/nixos/hardware-configuration.nix
```

Save this output. You'll paste it into `hosts/homelab/<hostname>/hardware.nix` in step 8.

## 7. Bootstrap a Minimal Config for First Boot

You need a minimal NixOS config to get through the first boot. This isn't the final flake-based config — it just gets the machine to a state where you can SSH in and deploy the real config.

```bash
cat > /mnt/etc/nixos/configuration.nix << 'EOF'
{ pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "homelab";

  # Enable SSH so you can reach it after reboot
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";  # temporary, removed once flake is deployed
  };
  networking.firewall.allowedTCPPorts = [ 22 ];

  users.users.trace = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # Paste your SSH public key here so you can log in without a password
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA4NmStNCItRU8uVCbD3BgJqkmlvG6WG4MpW57tVDkP5 trace@tailnet"
    ];
  };

  # Allow trace to sudo without password (easier for initial setup)
  security.sudo.wheelNeedsPassword = false;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [ vim git ];

  system.stateVersion = "26.05";
}
EOF
```

Install:

```bash
nixos-install --no-root-passwd
```

Reboot and remove the USB:

```bash
reboot
```

## 8. Add the Host to the Flake

Follow the [adding a host](adding-a-host.md) guide to:

1. Create `hosts/homelab/<hostname>/` with `default.nix` and `hardware.nix` (paste the output from step 6)
2. Register the host in `flake.nix` with `mkHomelabHost`
3. Set up secrets

`mkHomelabHost` provides core NixOS, docker, sops, tailscale, and home-manager with SSH — no desktop modules. See the [adding a host guide](adding-a-host.md) for the full module reference.

### LXQt + greetd auto-login

The host's `default.nix` should enable LXQt and greetd for a lightweight desktop that auto-logs in on boot:

```nix
# In hosts/homelab/<hostname>/default.nix
{ pkgs, ... }:
{
  imports = [ ./hardware.nix ];

  networking.hostName = "<hostname>";

  services = {
    xserver = {
      enable = true;
      desktopManager.lxqt.enable = true;
    };
    greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd startlxqt";
        user = "trace";
      };
      settings.initial_session = {
        command = "startlxqt";
        user = "trace";
      };
    };
  };

  system.stateVersion = "26.05";
}
```

This gives you a full desktop session through the KVM on boot, while SSH remains the primary management interface.

## 9. Deploy the Flake Config

SSH into the mini PC:

```bash
ssh trace@<mini-pc-ip>

# Clone the repo
git clone <your-repo-url> ~/Dev/other/nixos
cd ~/Dev/other/nixos

# Deploy
sudo nixos-rebuild switch --flake .#<hostname>
```

After this rebuild, the bootstrap config from step 7 is fully replaced by the flake. SSH will be locked down to Tailscale-only (via the tailscale module), and sops secrets will be decrypted.

## 10. Verify

```bash
# Tailscale is connected
tailscale status

# SSH works over tailnet from your workstation
ssh <hostname>

# Secrets are decrypted
ls -la ~/.ssh/personal_github_ed25519

# Docker is running (if you included docker.nix)
docker ps
```

## Post-Install: Day-to-Day Management

Rebuilds from your workstation over Tailscale:

```bash
# On the mini PC
cd ~/Dev/other/nixos
git pull
sudo nixos-rebuild switch --flake .#<hostname>
```

Or remotely:

```bash
nixos-rebuild switch --flake .#<hostname> --target-host trace@<hostname> --use-remote-sudo
```

The network KVM remains available as a fallback if SSH and Tailscale are both down.
