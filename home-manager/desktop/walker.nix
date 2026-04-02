{ config, lib, osConfig, ... }:
let
  # Full stylix application opacity as a float string for CSS alpha() calls.
  opacity    = toString osConfig.stylix.opacity.applications;
  # Reduced opacity for the pane background so Hyprland's blur shows through.
  bgOpacity  = toString (osConfig.stylix.opacity.applications * 0.35);
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

    @keyframes slide-pop {
      0%   { opacity: 0; transform: translateY(-24px) scale(0.92); }
      65%  { opacity: 1; transform: translateY(5px)   scale(1.03); }
      100% {             transform: translateY(0)     scale(1);    }
    }

    .box-wrapper {
      background: alpha(@base, ${bgOpacity});
      padding: 20px;
      border: 2px solid @accent;
      border-radius: 10px;
      min-width: 360px;
      max-width: 360px;
      animation: slide-pop 0.28s cubic-bezier(0.34, 1.56, 0.64, 1) both;
    }

    .search-container {
      background: alpha(@surface, ${opacity});
      border-radius: 6px;
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
      border-radius: 4px;
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



}
