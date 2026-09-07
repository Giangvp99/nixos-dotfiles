{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.programs.chrome;
in
{
  options.my.programs.chrome = {
    enable = lib.mkEnableOption "Chrome browser";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.google-chrome
    ];
  };
}
