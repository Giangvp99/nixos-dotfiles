{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.programs.onlyoffice;
in
{
  options.my.programs.onlyoffice.enable =
    lib.mkEnableOption "OnlyOffice Desktop Editors";

  config = lib.mkIf cfg.enable {
    programs.onlyoffice = {
      enable = true;
      package = pkgs.onlyoffice-desktopeditors;
    };
  };
}
