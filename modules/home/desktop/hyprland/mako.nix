{ config
, lib
, ...
}:

let
  cfg = config.my.desktop.hyprland;
in
{
  config = lib.mkIf cfg.enable {
    services.mako = {
      enable = true;

      settings = {
        default-timeout = 7000;
        ignore-timeout = false;

        width = 360;
        height = 160;

        margin = "10";
        padding = "12";

        border-size = 2;
        border-radius = 10;

        anchor = "top-right";

        font = "Fira Sans 11";

        background-color = "#1e1e2eee";
        text-color = "#cdd6f4";
        border-color = "#89b4fa";

        icons = true;
        max-icon-size = 48;
      };
    };
  };
}
