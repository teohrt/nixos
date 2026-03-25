{ ... }: {
  programs.git = {
    enable = true;
    userName = "Trace Ohrt";
    userEmail = "teohrt18@gmail.com";
    extraConfig = {
      pull.rebase = false;
      core.editor = "nvim";
    };
  };
}
