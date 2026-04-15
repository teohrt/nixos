{ ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        extraOptions = {
          AddKeysToAgent = "yes";
        };
      };
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/personal_github_ed25519";
      };
      "github.com-work" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/work_github_ed25519";
      };
    };
  };

  services.ssh-agent.enable = true;
}
