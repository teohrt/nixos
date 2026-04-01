{ config, lib, osConfig, ... }:
let
  # Convert stylix.opacity.applications (0.0–1.0) to a two-digit hex alpha
  # so the Walker background opacity stays in sync with other applications.
  alpha    = builtins.floor (osConfig.stylix.opacity.applications * 255);
  alphaHex = lib.fixedWidthString 2 "0" (lib.toHexString alpha);
in
{
  xdg.configFile."walker/config.toml".text = ''
    force_keyboard_focus = true
    selection_wrap = true
    theme = "stylix"
    hide_action_hints = true

    [placeholders]
    "default" = { input = "Search...", list = "No Results" }

    [keybinds]
    quick_activate = []

    [providers]
    max_results = 256
    default = ["desktopapplications"]
  '';

  xdg.configFile."walker/themes/stylix.css".text = ''
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
      color: #${config.lib.stylix.colors.base05};
      font-family: "${config.stylix.fonts.monospace.name}", monospace;
      font-size: ${toString config.stylix.fonts.sizes.applications}px;
    }

    #box {
      background: #${config.lib.stylix.colors.base00}${alphaHex};
      padding: 16px;
      border-right: 1px solid #${config.lib.stylix.colors.base02}80;
      min-width: 340px;
      max-width: 340px;
    }

    #search {
      background: #${config.lib.stylix.colors.base01}${alphaHex};
      border-radius: 6px;
      padding: 10px 14px;
      margin-bottom: 10px;
    }

    #input placeholder {
      opacity: 0.5;
    }

    child {
      padding: 6px 8px;
      border-radius: 4px;
    }

    child:selected,
    child:hover {
      background: #${config.lib.stylix.colors.base02}${alphaHex};
    }

    child:selected #label,
    child:hover #label {
      color: #${config.lib.stylix.colors.base0D};
    }

    #label {
      font-weight: 500;
      color: #${config.lib.stylix.colors.base05};
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

  xdg.configFile."walker/themes/stylix.toml".text = ''
    [ui.anchors]
    bottom = true
    left = true
    right = false
    top = true

    [ui.window]
    h_align = "fill"
    v_align = "fill"

    [ui.window.box]
    h_align = "start"
    v_align = "fill"

    [ui.window.box.scroll]
    v_expand = true

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
