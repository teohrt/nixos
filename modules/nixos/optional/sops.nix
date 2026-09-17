{ username, ... }:
{
  sops = {
    defaultSopsFile = ../../../secrets/secrets.yaml;
    age.keyFile = "/home/${username}/.config/sops/age/keys.txt";

    secrets = {
      "personal_github_ssh_private_key" = {
        owner = username;
        group = "users";
        mode = "0600";
        path = "/home/${username}/.ssh/personal_github_ed25519";
      };

      "work_github_ssh_private_key" = {
        owner = username;
        group = "users";
        mode = "0600";
        path = "/home/${username}/.ssh/work_github_ed25519";
      };

      # Two-line file: first line = username, second line = password.
      # Credentials from https://www.expressvpn.com/setup#manual (OpenVPN tab).
      "expressvpn_credentials" = {
        mode = "0400";
      };
    };
  };
}
