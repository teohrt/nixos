{ ... }: {
  xdg.configFile."walker/config.toml".text = ''
    force_keyboard_focus = true
    selection_wrap = true
    theme = "default"
    hide_action_hints = true

    [placeholders]
    "default" = { input = "Search...", list = "No Results" }

    [keybinds]
    quick_activate = []

    [providers]
    max_results = 256
    default = ["desktopapplications"]
  '';

  xdg.configFile."walker/themes/default/style.css".text = ''
    * {
      all: unset;
    }

    * {
      font-family: "JetBrains Mono", monospace;
      font-size: 14px;
      color: #ffffff;
    }

    scrollbar {
      opacity: 0;
    }

    .normal-icons {
      -gtk-icon-size: 16px;
    }

    .large-icons {
      -gtk-icon-size: 32px;
    }

    .box-wrapper {
      background: rgba(10, 10, 15, 0.95);
      padding: 20px;
      border: 2px solid rgba(255, 255, 255, 0.15);
    }

    .search-container {
      background: rgba(17, 17, 24, 0.9);
      padding: 10px;
    }

    .input placeholder {
      opacity: 0.5;
    }

    .input:focus,
    .input:active {
      box-shadow: none;
      outline: none;
    }

    child:selected .item-box * {
      color: #7ebae4;
    }

    .item-box {
      padding-left: 14px;
    }

    .item-text-box {
      all: unset;
      padding: 14px 0;
    }

    .item-subtext {
      font-size: 0px;
      min-height: 0px;
      margin: 0px;
      padding: 0px;
    }

    .item-image {
      margin-right: 14px;
      -gtk-icon-transform: scale(0.9);
    }
  '';

  xdg.configFile."walker/themes/default/layout.xml".source = ./walker-layout.xml;
}
