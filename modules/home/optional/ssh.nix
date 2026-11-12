_: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        AddKeysToAgent = "yes";
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
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
      "thinkpad" = {
        HostName = "my-thinkpad";
        User = "trace";
        IdentityFile = "~/.ssh/tailscale_ed25519";
      };
      "framework" = {
        HostName = "framework-16";
        User = "trace";
        IdentityFile = "~/.ssh/tailscale_ed25519";
      };
    };
  };

  services.ssh-agent.enable = true;
}
