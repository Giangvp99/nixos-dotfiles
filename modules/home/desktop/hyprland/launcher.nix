{ config
, lib
, ...
}:

let
  cfg = config.my.desktop.hyprland;
in
{
  config = lib.mkIf cfg.enable {
    programs.fuzzel = {
      enable = true;

      settings = {
        main = {
          inherit (cfg) terminal;

          width = 50;
          lines = 12;

          font = "Fira Sans:size=12";
          icons-enabled = true;

          horizontal-pad = 20;
          vertical-pad = 14;

          layer = "overlay";
        };

        colors = {
          background = "1e1e2eee";
          text = "cdd6f4ff";
          match = "89b4faff";
          selection = "313244ff";
          selection-text = "f5e0dcff";
          border = "89b4faff";
        };

        border = {
          width = 2;
          radius = 10;
        };
      };
    };
  };
}
