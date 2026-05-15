# Walker: GTK4 application launcher with dmenu mode for custom pickers.
# Used for app launching (Super+Space) and various dmenu-style selectors
# (wallpaper picker, keybindings menu, power menu, etc.)
{ config, lib, pkgs, pkgs-walker, ... }:
let
  # Full stylix application opacity as a float string for CSS alpha() calls.
  opacity    = toString config.stylix.opacity.applications;
  # Reduced opacity for the pane background so Hyprland's blur shows through.
  bgOpacity  = toString (config.stylix.opacity.applications * 0.35);
in
{
  xdg.configFile."walker/config.toml".text = ''
    force_keyboard_focus = true
    selection_wrap = true
    theme = "stylix-nixos"
    additional_theme_location = "~/.config/walker/themes/"
    hide_action_hints = true

    [placeholders]
    "default" = { input = "Launch", list = "No Results" }
    "calc" = { input = "Search...", list = "boom, quick maths" }

    [keybinds]
    quick_activate = []

    [providers]
    max_results = 256
    default = ["desktopapplications", "calc"]
  '';

  # Walker 2.x themes are directories containing layout.xml + style.css.
  # CSS uses class selectors (.box-wrapper, .input, etc.) and @define-color variables.

  xdg.configFile."walker/themes/stylix-nixos/style.css".text = ''
    @define-color text       #${config.lib.stylix.colors.base05};
    @define-color base       #${config.lib.stylix.colors.base00};
    @define-color surface    #${config.lib.stylix.colors.base01};
    @define-color overlay    #${config.lib.stylix.colors.base02};
    @define-color accent     #${config.lib.stylix.colors.base0D};
    @define-color border     #${config.lib.stylix.colors.base02};

    * {
      all: unset;
    }

    * {
      font-family: "${config.stylix.fonts.monospace.name}", monospace;
      font-size: ${toString (config.stylix.fonts.sizes.applications + 4)}px;
      color: @text;
    }

    scrollbar {
      opacity: 0;
    }

    .box-wrapper {
      background: rgba(0, 0, 0, 0.95);
      padding: 20px;
      border: 1px solid @accent;
      border-radius: 0;
      min-width: 360px;
      max-width: 360px;
    }

    .search-container {
      background: alpha(@surface, ${opacity});
      border-radius: 0;
      padding: 12px 16px;
    }

    .input placeholder {
      opacity: 0.5;
    }

    .input:focus,
    .input:active {
      box-shadow: none;
      outline: none;
    }

    child:hover .item-box,
    child:selected .item-box {
      background: alpha(@overlay, ${opacity});
      border-radius: 0;
    }

    child:selected .item-box * {
      color: @accent;
    }

    .item-box {
      padding: 10px 12px;
    }

    .item-text-box {
      all: unset;
    }

    .item-subtext {
      font-size: 0px;
      min-height: 0px;
      margin: 0px;
      padding: 0px;
    }

    .item-image {
      margin-right: 10px;
    }

  '';

  # Calc provider item layout: stripped the GtkImage (which shows a broken icon
  # since calc results have no app icon) and the unused ItemImageFont label.
  xdg.configFile."walker/themes/stylix-nixos/item_calc.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <interface>
      <requires lib="gtk" version="4.0"></requires>
      <object class="GtkBox" id="ItemBox">
        <style><class name="item-box"></class></style>
        <property name="orientation">horizontal</property>
        <property name="spacing">10</property>
        <child>
          <object class="GtkBox" id="ItemTextBox">
            <style><class name="item-text-box"></class></style>
            <property name="orientation">vertical</property>
            <property name="hexpand">true</property>
            <property name="vexpand">true</property>
            <property name="vexpand-set">true</property>
            <property name="spacing">0</property>
            <child>
              <object class="GtkLabel" id="ItemText">
                <style><class name="item-text"></class></style>
                <property name="wrap">false</property>
                <property name="vexpand_set">true</property>
                <property name="vexpand">true</property>
                <property name="xalign">0</property>
              </object>
            </child>
            <child>
              <object class="GtkLabel" id="ItemSubtext">
                <style><class name="item-subtext"></class></style>
                <property name="wrap">true</property>
                <property name="vexpand_set">true</property>
                <property name="vexpand">true</property>
                <property name="xalign">0</property>
                <property name="yalign">0</property>
              </object>
            </child>
          </object>
        </child>
      </object>
    </interface>
  '';

  xdg.configFile."walker/themes/stylix-nixos/layout.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <interface>
      <requires lib="gtk" version="4.0"></requires>
      <object class="GtkWindow" id="Window">
        <style><class name="window"></class></style>
        <property name="resizable">true</property>
        <property name="title">Walker</property>
        <child>
          <object class="GtkBox" id="BoxWrapper">
            <style><class name="box-wrapper"></class></style>
            <property name="overflow">hidden</property>
            <property name="orientation">horizontal</property>
            <property name="valign">center</property>
            <property name="halign">center</property>
            <child>
              <object class="GtkBox" id="Box">
                <style><class name="box"></class></style>
                <property name="orientation">vertical</property>
                <property name="hexpand">true</property>
                <property name="hexpand-set">true</property>
                <property name="vexpand">true</property>
                <property name="vexpand-set">true</property>
                <property name="spacing">10</property>
                <child>
                  <object class="GtkBox" id="SearchContainer">
                    <style><class name="search-container"></class></style>
                    <property name="overflow">hidden</property>
                    <property name="orientation">horizontal</property>
                    <property name="halign">fill</property>
                    <property name="hexpand">true</property>
                    <property name="hexpand-set">true</property>
                    <child>
                      <object class="GtkEntry" id="Input">
                        <style><class name="input"></class></style>
                        <property name="halign">fill</property>
                        <property name="hexpand">true</property>
                        <property name="hexpand-set">true</property>
                      </object>
                    </child>
                  </object>
                </child>
                <child>
                  <object class="GtkBox" id="ContentContainer">
                    <style><class name="content-container"></class></style>
                    <property name="orientation">horizontal</property>
                    <property name="spacing">10</property>
                    <property name="vexpand">true</property>
                    <property name="vexpand-set">true</property>
                    <child>
                      <object class="GtkLabel" id="ElephantHint">
                        <style><class name="elephant-hint"></class></style>
                        <property name="hexpand">true</property>
                        <property name="height-request">100</property>
                        <property name="label">Waiting for elephant...</property>
                      </object>
                    </child>
                    <child>
                      <object class="GtkLabel" id="Placeholder">
                        <style><class name="placeholder"></class></style>
                        <property name="label">No Results</property>
                        <property name="yalign">0.0</property>
                        <property name="hexpand">true</property>
                      </object>
                    </child>
                    <child>
                      <object class="GtkScrolledWindow" id="Scroll">
                        <style><class name="scroll"></class></style>
                        <property name="hexpand">true</property>
                        <property name="can_focus">false</property>
                        <property name="overlay-scrolling">true</property>
                        <property name="max-content-height">500</property>
                        <property name="propagate-natural-height">true</property>
                        <property name="hscrollbar-policy">automatic</property>
                        <property name="vscrollbar-policy">automatic</property>
                        <child>
                          <object class="GtkGridView" id="List">
                            <style><class name="list"></class></style>
                            <property name="max_columns">1</property>
                            <property name="can_focus">false</property>
                          </object>
                        </child>
                      </object>
                    </child>
                    <child>
                      <object class="GtkBox" id="Preview">
                        <style><class name="preview"></class></style>
                      </object>
                    </child>
                  </object>
                </child>
                <child>
                  <object class="GtkBox" id="Keybinds">
                    <style><class name="keybinds"></class></style>
                    <property name="hexpand">true</property>
                    <child>
                      <object class="GtkBox" id="GlobalKeybinds">
                        <style><class name="global-keybinds"></class></style>
                        <property name="spacing">10</property>
                      </object>
                    </child>
                    <child>
                      <object class="GtkBox" id="ItemKeybinds">
                        <style><class name="item-keybinds"></class></style>
                        <property name="hexpand">true</property>
                        <property name="halign">end</property>
                        <property name="spacing">10</property>
                      </object>
                    </child>
                  </object>
                </child>
                <child>
                  <object class="GtkLabel" id="Error">
                    <style><class name="error"></class></style>
                    <property name="xalign">0</property>
                    <property name="visible">false</property>
                  </object>
                </child>
              </object>
            </child>
          </object>
        </child>
      </object>
    </interface>
  '';

  # Disable calc history so selected results don't persist across sessions.
  xdg.configFile."elephant/calc.toml".text = ''
    max_items = 0
  '';

  # Systemd services for walker and elephant instead of hyprland exec-once:
  # - More reliable startup (exec-once shell commands can fail silently)
  # - Automatic restart on crash
  # - Proper dependency ordering (walker waits for elephant)
  # - Cleaner logs via journalctl --user -u walker/elephant

  systemd.user.services.elephant = {
    Unit = {
      Description = "Elephant app indexer for Walker";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs-walker.elephant}/bin/elephant";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  systemd.user.services.walker = {
    Unit = {
      Description = "Walker application launcher";
      After = [ "graphical-session.target" "elephant.service" ];
      PartOf = [ "graphical-session.target" ];
      Requires = [ "elephant.service" ];
    };
    Service = {
      ExecStart = "${pkgs-walker.walker}/bin/walker --gapplication-service";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
