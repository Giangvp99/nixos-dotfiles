{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.desktop.fonts;
in
{
  options.my.desktop.fonts.enable = lib.mkEnableOption "Fonts config";

  config = lib.mkIf cfg.enable {
    fonts.packages = with pkgs; [
      corefonts # Includes Times New Roman, Arial, Verdana, etc.
    ];
  };
}
