{ ... }:

let
  sharedCss = ''
    #window,
    #box,
    #search,
    #input,
    #prompt,
    #clear,
    #typeahead,
    #list,
    child,
    scrollbar,
    slider,
    #item,
    #text,
    #label,
    #bar,
    #sub,
    #activationlabel {
      all: unset;
    }

    #window {
      color: #ffffff;
      font-family: "JetBrains Mono", monospace;
      font-size: 14px;
    }

    #box {
      background: rgba(10, 10, 15, 0.95);
      padding: 20px;
      border: 1px solid rgba(255, 255, 255, 0.1);
    }

    #search {
      background: rgba(17, 17, 24, 0.9);
      padding: 10px;
      margin-bottom: 8px;
    }

    #input placeholder {
      opacity: 0.5;
    }

    child {
      padding: 4px 8px;
    }

    child:selected,
    child:hover {
      background: rgba(17, 17, 24, 0.9);
    }

    child:selected #label,
    child:hover #label {
      color: #7ebae4;
    }

    #label {
      font-weight: 500;
    }

    #sub {
      font-size: 0px;
    }

    #icon {
      margin-right: 8px;
    }

    #activationlabel {
      opacity: 0;
      min-width: 0;
    }
  '';
in
{
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

  # Shared styles for both themes
  xdg.configFile."walker/themes/default.css".text = sharedCss;
  xdg.configFile."walker/themes/power.css".text = sharedCss;

  # Layout for the app launcher
  xdg.configFile."walker/themes/default.toml".text = ''
    [ui.anchors]
    bottom = true
    left = true
    right = true
    top = true

    [ui.window]
    h_align = "fill"
    v_align = "fill"

    [ui.window.box]
    h_align = "center"
    width = 500

    [ui.window.box.margins]
    top = 200

    [ui.window.box.scroll.list]
    max_height = 300
    max_width = 480
    min_width = 480
    width = 480

    [ui.window.box.scroll.list.item.activation_label]
    h_align = "fill"
    v_align = "fill"
    width = 0

    [ui.window.box.scroll.list.item.icon]
    pixel_size = 26
    theme = ""

    [ui.window.box.scroll.list.margins]
    top = 8

    [ui.window.box.search.input]
    h_align = "fill"
    h_expand = true
    icons = false

    [ui.window.box.search.spinner]
    hide = true
  '';

  # Smaller layout for the power menu
  xdg.configFile."walker/themes/power.toml".text = ''
    [ui.anchors]
    bottom = true
    left = true
    right = true
    top = true

    [ui.window]
    h_align = "fill"
    v_align = "fill"

    [ui.window.box]
    h_align = "center"
    width = 250

    [ui.window.box.margins]
    top = 200

    [ui.window.box.scroll.list]
    max_height = 300
    max_width = 230
    min_width = 230
    width = 230

    [ui.window.box.scroll.list.item.activation_label]
    h_align = "fill"
    v_align = "fill"
    width = 0

    [ui.window.box.scroll.list.item.icon]
    pixel_size = 0
    theme = ""

    [ui.window.box.scroll.list.margins]
    top = 8

    [ui.window.box.search.input]
    h_align = "fill"
    h_expand = true
    icons = false

    [ui.window.box.search.spinner]
    hide = true
  '';
}
