{ ... }:

{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "hyprlock";
        before_sleep_cmd = "hyprlock";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 300;   # 5 minutes — lock screen
          on-timeout = "hyprlock";
        }
        {
          timeout = 600;   # 10 minutes — suspend
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
