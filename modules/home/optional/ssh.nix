_: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        AddKeysToAgent = "yes";
      };
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/personal_github_ed25519";
      };
      "github.com-work" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/work_github_ed25519";
      };
    };
  };

  services.ssh-agent.enable = true;
}
