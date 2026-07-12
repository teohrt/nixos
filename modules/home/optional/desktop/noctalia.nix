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
        position = "bottom";
        scale = 1.3;
        widget_spacing = 32;
        radius = 0;
        margin_edge = 0;
        margin_ends = 0;
        start = [ "workspaces" ];
        center = [
          "battery"
          "clock"
          "notifications"
        ];
        end = [
          "cpu"
          "ram"
          "temp"
          "network"
          "bluetooth"
          "volume"
          "control-center"
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

      location.address = "Brooklyn, NY";

      dock.enabled = false;
      desktop_widgets.enabled = true;
      lockscreen_widgets.enabled = false;

      notification = {
        show_actions = false;
        show_app_name = false;
      };

      osd = {
        position = "top_right";
        kinds.media = false;
      };

      shell = {
        external_ip_enabled = true;
        ui_scale = 1.2;
        animation.speed = 1.6;
        screenshot.directory = "/home/trace/Pictures/Screenshots";
        panel = {
          control_center_placement = "attached";
          open_near_click_control_center = true;
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
            shortcut = "3";
            enabled = true;
            countdown_seconds = 0.0;
            variant = "default";
          }
          {
            action = "shutdown";
            shortcut = "4";
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
        cpu.display = "text";
        notification-history.enabled = true;
        ram = {
          show_label = false;
          display = "text";
          stat = "ram_pct";
        };
        temp.display = "text";
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
