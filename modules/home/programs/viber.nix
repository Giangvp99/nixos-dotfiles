{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.programs.viber;
in
{
  options.my.programs.viber.enable =
    lib.mkEnableOption "Viber Desktop";

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.viber
    ];
  };
}
