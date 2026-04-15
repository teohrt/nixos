# Secrets Management with sops-nix

This repo uses [sops-nix](https://github.com/Mic92/sops-nix) with age encryption to manage secrets like SSH keys.

## How It Works

- Secrets are encrypted in `secrets/secrets.yaml` and committed to git
- Each host has an age key at `/var/lib/sops-nix/key.txt`
- On rebuild, sops-nix decrypts secrets and places them at configured paths
- After a reimage, just restore the age key and rebuild — secrets decrypt automatically

## Initial Setup (One-Time)

### 1. Generate Admin Key

Store this somewhere safe (password manager, encrypted backup). It lets you re-encrypt secrets from any machine.

```bash
nix-shell -p age --run "age-keygen -o admin.key"
# Save the public key (age1...) and store admin.key securely
```

### 2. Generate Host Key

Run on each host:

```bash
sudo mkdir -p /var/lib/sops-nix
nix-shell -p age --run "sudo age-keygen -o /var/lib/sops-nix/key.txt"
sudo chmod 600 /var/lib/sops-nix/key.txt
```

Note the public key printed (starts with `age1...`).

### 3. Update .sops.yaml

Add public keys to `.sops.yaml`:

```yaml
keys:
  - &admin age1your-admin-public-key...
  - &framework-16 age1your-framework-16-public-key...
  - &my-thinkpad age1your-thinkpad-public-key...

creation_rules:
  - path_regex: secrets/secrets\.yaml$
    key_groups:
      - age:
          - *admin
          - *framework-16
          - *my-thinkpad
```

### 4. Create GitHub SSH Key

```bash
ssh-keygen -t ed25519 -C "github" -f /tmp/personal_github_ed25519
# Add /tmp/personal_github_ed25519.pub to GitHub: Settings > SSH Keys
```

### 5. Create Encrypted Secrets File

```bash
# Set SOPS_AGE_KEY_FILE to your admin key (or host key)
export SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt

# Create and edit secrets file
nix-shell -p sops --run "sops secrets/secrets.yaml"
```

Add your secrets in the editor:

```yaml
personal_github_ssh_private_key: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    <paste contents of /tmp/personal_github_ed25519>
    -----END OPENSSH PRIVATE KEY-----
```

Save and exit. The file is now encrypted.

### 6. Clean Up

```bash
rm /tmp/personal_github_ed25519 /tmp/personal_github_ed25519.pub
```

### 7. Rebuild

```bash
sudo nixos-rebuild switch --flake .#framework-16
```

Verify:

```bash
ls -la ~/.ssh/personal_github_ed25519
ssh -T git@github.com
```

## Adding a New Host

1. Generate age key on the new host (see step 2 above)
2. Send the public key to a machine that can decrypt secrets
3. Add the public key to `.sops.yaml`
4. Re-encrypt secrets with the new key:

```bash
export SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt
nix-shell -p sops --run "sops updatekeys secrets/secrets.yaml"
```

5. Commit and push
6. Pull on the new host and rebuild

## After a Reimage

1. Restore `/var/lib/sops-nix/key.txt` from backup
2. Set permissions: `sudo chmod 600 /var/lib/sops-nix/key.txt`
3. Clone the repo and rebuild — secrets decrypt automatically

## Adding New Secrets

Edit the secrets file:

```bash
export SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt
nix-shell -p sops --run "sops secrets/secrets.yaml"
```

Then add corresponding entries in `modules/nixos/optional/sops.nix`:

```nix
secrets."my-new-secret" = {
  owner = "trace";
  mode = "0600";
  path = "/path/to/secret";
};
```

## Troubleshooting

### "Failed to get the data key"

The host's age key can't decrypt the secrets file. Either:
- The key isn't in `.sops.yaml`
- You need to run `sops updatekeys` to re-encrypt with the new key

### Secret file has wrong permissions

Check that the sops.nix module sets correct `owner`, `group`, and `mode`.

### Key file not found

Ensure `/var/lib/sops-nix/key.txt` exists and has `chmod 600`.
