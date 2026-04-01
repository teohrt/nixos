{ config, lib, pkgs-walker, osConfig, ... }:
let
  # Full stylix application opacity — used for interactive surfaces (search bar, hover).
  alpha    = builtins.floor (osConfig.stylix.opacity.applications * 255);
  alphaHex = lib.fixedWidthString 2 "0" (lib.toHexString alpha);
  # Low-opacity tint for the pane background so Hyprland's blur shows through.
  bgAlpha    = builtins.floor (osConfig.stylix.opacity.applications * 0.35 * 255);
  bgAlphaHex = lib.fixedWidthString 2 "0" (lib.toHexString bgAlpha);
in
{
  xdg.configFile."walker/config.toml".text = ''
    force_keyboard_focus = true
    selection_wrap = true
    theme = "stylix-nixos"
    additional_theme_location = "~/.config/walker/themes/"
    hide_action_hints = true

    [placeholders]
    "default" = { input = "Search...", list = "No Results" }

    [keybinds]
    quick_activate = []

    [providers]
    max_results = 256
    default = ["desktopapplications"]
  '';

  xdg.configFile."walker/themes/stylix-nixos.css".text = ''
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
      background: #${config.lib.stylix.colors.base00}${bgAlphaHex};
      padding: 20px;
      border-right: 2px solid #${config.lib.stylix.colors.base02}80;
      min-width: 360px;
      max-width: 360px;
    }

    #search {
      background: #${config.lib.stylix.colors.base01}${alphaHex};
      border-radius: 6px;
      padding: 12px 16px;
      margin-bottom: 12px;
    }

    #input placeholder {
      opacity: 0.5;
    }

    child {
      padding: 10px 12px;
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

  xdg.configFile."walker/themes/stylix-nixos.toml".text = ''
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

  systemd.user.services.walker = {
    Unit = {
      Description = "Walker application launcher";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStartPre = "${lib.getExe pkgs-walker.elephant}";
      ExecStart = "${pkgs-walker.walker}/bin/walker --gapplication-service";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Restart walker after every home-manager switch so theme/config changes
  # take effect immediately without requiring a logout.
  home.activation.restartWalker = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if $DRY_RUN_CMD systemctl --user -q is-active walker.service; then
      $DRY_RUN_CMD systemctl --user restart walker.service
    fi
  '';

}
