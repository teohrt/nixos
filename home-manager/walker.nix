{ config, ... }:
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

  xdg.configFile."walker/themes/default.css".text = ''
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
      color: @window_fg_color;
      font-family: "${config.stylix.fonts.monospace.name}", monospace;
      font-size: ${toString config.stylix.fonts.sizes.applications}px;
    }

    #box {
      background: @window_bg_color;
      padding: 20px;
      border: 1px solid @borders;
    }

    #search {
      background: @view_bg_color;
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
      background: @view_bg_color;
    }

    child:selected #label,
    child:hover #label {
      color: @accent_color;
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

    [ui.window.box.margins]
    top = 200

    [ui.window.box.scroll.list]

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

}
