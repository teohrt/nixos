{ ... }: {
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Trace Ohrt";
        email = "teohrt18@gmail.com";
      };
      pull.rebase = false;
      core.editor = "nvim";
    };
  };
}
