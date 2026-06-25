{ username, ... }:
{
  sops = {
    defaultSopsFile = ../../../secrets/secrets.yaml;
    age.keyFile = "/home/${username}/.config/sops/age/keys.txt";

    secrets."personal_github_ssh_private_key" = {
      owner = username;
      group = "users";
      mode = "0600";
      path = "/home/${username}/.ssh/personal_github_ed25519";
    };

    secrets."work_github_ssh_private_key" = {
      owner = username;
      group = "users";
      mode = "0600";
      path = "/home/${username}/.ssh/work_github_ed25519";
    };
  };
}
