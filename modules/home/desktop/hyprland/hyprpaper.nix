{ config
, lib
, ...
}:

let
  cfg = config.my.desktop.hyprland;
in
{
  config = lib.mkIf cfg.enable {
    services.hyprpaper = {
      enable = true;

      settings = {
        ipc = true;
        splash = false;

        wallpaper = [
          {
            monitor = "eDP-1";
            path = "${./config/wallpaper.jpg}";
            fit_mode = "cover";
          }
        ];
      };
    };
  };
}
