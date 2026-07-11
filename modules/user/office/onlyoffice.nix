{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.userSettings.onlyoffice;
in
{
  options = {
    userSettings.onlyoffice = {
      enable = lib.mkEnableOption "Enable onlyoffice";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.onlyoffice.enable = true;
    programs.onlyoffice.package = pkgs.onlyoffice-desktopeditors;

  };
}
