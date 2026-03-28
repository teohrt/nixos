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
      font-family: "JetBrains Mono", monospace;
      font-size: 14px;
      color: #ffffff;
    }

    scrollbar {
      opacity: 0;
    }

    .box-wrapper {
      background: rgba(10, 10, 15, 0.95);
      border-radius: 12px;
      padding: 12px;
    }

    .input image {
      opacity: 0;
      min-width: 0;
      min-height: 0;
    }

    .search-container {
      background: rgba(17, 17, 24, 0.9);
      border-radius: 8px;
      padding: 10px 14px;
      margin-bottom: 8px;
    }

    .input placeholder {
      color: rgba(255, 255, 255, 0.35);
    }

    child:selected .item-box {
      background: rgba(17, 17, 24, 0.9);
      border-radius: 8px;
    }

    child:selected .item-box * {
      color: #ffffff;
    }

    child .item-box {
      padding: 8px 10px;
      border-radius: 8px;
    }

    child .item-box * {
      color: rgba(255, 255, 255, 0.35);
    }

    .normal-icons {
      -gtk-icon-size: 16px;
    }
  '';

  xdg.configFile."walker/themes/default/layout.xml".source = ./walker-layout.xml;
}
