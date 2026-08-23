{ config
, lib
, ...
}:

let
  cfg = config.my.desktop.hyprland;
in
{
  config = lib.mkIf cfg.enable {
    programs.hyprlock = {
      enable = true;

      settings = {
        general = {
          disable_loading_bar = true;
          hide_cursor = true;
          grace = 2;
        };

        background = [
          {
            monitor = "";
            path = "screenshot";
            blur_passes = 3;
            blur_size = 8;
          }
        ];

        label = [
          {
            monitor = "";
            text = "$TIME";
            font_size = 64;
            position = "0, 160";
            halign = "center";
            valign = "center";
          }
          {
            monitor = "";
            text = "Hello, $USER";
            font_size = 18;
            position = "0, 90";
            halign = "center";
            valign = "center";
          }
        ];

        input-field = [
          {
            monitor = "";

            size = "300, 50";
            position = "0, 0";

            halign = "center";
            valign = "center";

            outline_thickness = 2;

            placeholder_text = "Enter password";
            fail_text = "Retry";

            dots_center = true;
            fade_on_empty = false;
          }
        ];
      };
    };
  };
}
