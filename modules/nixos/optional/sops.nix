{ ... }:
{
  sops = {
    defaultSopsFile = ../../../secrets/secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets."personal_github_ssh_private_key" = {
      owner = "trace";
      group = "users";
      mode = "0600";
      path = "/home/trace/.ssh/personal_github_ed25519";
    };
  };
}
