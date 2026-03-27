{ pkgs, ... }: {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    extraConfig = {
      modi = "drun,window";
      show-icons = true;
      drun-display-format = "{name}";
      disable-history = false;
      hide-scrollbar = true;
      display-drun = "";
      display-window = "";
      scroll-method = 0;
      font = "JetBrains Mono 13";
    };
    theme = builtins.toFile "rofi-theme.rasi" ''
      * {
        bg:      #0a0a0f;
        bg-alt:  #111118;
        fg:      #ffffff;
        fg-dim:  rgba(255,255,255,0.35);
        accent:  #7ebae4;

        background-color: transparent;
        text-color:       @fg;
        border:           0;
        margin:           0;
        padding:          0;
        spacing:          0;
      }

      window {
        width:            420px;
        background-color: @bg;
        border-radius:    12px;
        padding:          12px;
      }

      inputbar {
        background-color: @bg-alt;
        border-radius:    8px;
        padding:          10px 14px;
        margin:           0 0 8px 0;
        children:         [entry];
      }

      entry {
        placeholder:       "search...";
        placeholder-color: @fg-dim;
      }

      listview {
        lines:     8;
        scrollbar: false;
      }

      element {
        border-radius: 8px;
        padding:       10px 12px;
        spacing:       10px;
      }

      element-icon {
        size:          20px;
      }

      element-text {
        vertical-align: 0.5;
      }

      element normal normal {
        text-color: @fg-dim;
      }

      element selected normal {
        background-color: @bg-alt;
        text-color:       @fg;
      }

      element alternate normal {
        background-color: transparent;
      }
    '';
  };
}
