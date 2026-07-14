# Noctalia v5: bar, launcher, notifications, lock screen, OSD.
# Replaces waybar, walker, swaync, hyprlock, swayosd, and swww/mpvpaper.
# Hypridle is kept separately for the custom tte screensaver.
{ lib, noctalia, ... }:
{
  imports = [ noctalia.homeModules.default ];

  programs.noctalia = {
    enable = true;

    settings = {
      audio.enable_overdrive = true;

      bar.main = {
        position = "top";
        scale = 1.3;
        hover_highlight = false;
        widget_spacing = 20;
        radius = 80;
        margin_edge = 0;
        margin_ends = 500;
        margin_opposite_edge = 0;
        shadow = false;
        capsule_padding = 15.0;
        capsule_radius = 21;
        capsule_thickness = 1.0;
        start = [
          "control-center"
          "workspaces"
        ];
        center = [
          "battery"
          "clock"
          "notifications"
        ];
        end = [
          "cpu"
          "ram"
          "bluetooth"
          "volume"
          "network"
        ];
      };

      control_center = {
        sidebar = "none";
        sidebar_section = "none";
        calendar.show_events_card = true;
      };

      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Nord";
      };

      location.auto_locate = true;

      plugins.enabled = [ "noctalia/wallhaven" ];

      plugin_settings."noctalia/wallhaven" = {
        browser_placement = "floating";
        browser_position = "center";
      };

      dock.enabled = false;
      desktop_widgets.enabled = true;
      lockscreen_widgets.enabled = false;

      notification = {
        show_actions = false;
        show_app_name = false;
        offset_x = 15;
        offset_y = 0;
      };

      osd = {
        position = "top_center";
        offset_y = 20;
        kinds.media = false;
      };

      shell = {
        external_ip_enabled = true;
        animation.speed = 1.6;
        screenshot.directory = "/home/trace/Pictures/Screenshots";
        panel = {
          open_near_click_control_center = true;
          borders = false;
          floating_offset = 0;
          wallpaper_placement = "floating";
          wallpaper_position = "center";
        };
        session.actions = [
          {
            action = "lock";
            shortcut = "1";
            enabled = true;
            countdown_seconds = 0.0;
            variant = "default";
          }
          {
            action = "logout";
            shortcut = "2";
            enabled = true;
            countdown_seconds = 0.0;
            variant = "default";
          }
          {
            action = "reboot";
            shortcut = "4";
            enabled = true;
            countdown_seconds = 0.0;
            variant = "default";
          }
          {
            action = "shutdown";
            shortcut = "5";
            enabled = true;
            countdown_seconds = 0.0;
            variant = "destructive";
          }
        ];
      };

      widget = {
        clock = {
          format = "{:%-I:%M %p}";
          anchor = true;
        };
        control-center.glyph = "snowflake";
        cpu.show_label = false;
        ram = {
          show_label = false;
          stat = "ram_pct";
        };
        battery = {
          display_mode = "graphic";
          show_label = false;
          scale = 0.7;
        };
        network.show_label = false;
        volume.show_label = false;
        sysmon = {
          display = "graph";
          glyph = "cpu-usage";
          show_label = false;
        };
        workspaces = {
          focused_color = "outline";
          occupied_color = "on_tertiary";
          empty_color = "on_tertiary";
          scale = 1.3;
        };
      };
    };
  };

  # Let Noctalia use its own theming; disable Stylix's hyprpaper target
  stylix.targets.hyprpaper.enable = lib.mkForce false;
}
