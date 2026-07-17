{ config
, lib
, ...
}:

let
  cfg = config.my.desktop.stylixTargets;
in
{
  options.my.desktop.stylixTargets.enable =
    lib.mkEnableOption "Stylix targets for the user desktop";

  config = lib.mkIf cfg.enable {
    stylix.targets = {
      alacritty.enable = true;
      gtk.enable = false;
      kde.enable = true;
      kitty.enable = false;
      qt.enable = false;
    };

    fonts.fontconfig.defaultFonts = {
      monospace = [
        config.stylix.fonts.monospace.name
      ];

      sansSerif = [
        config.stylix.fonts.sansSerif.name
      ];

      serif = [
        config.stylix.fonts.serif.name
      ];
    };
  };
}
