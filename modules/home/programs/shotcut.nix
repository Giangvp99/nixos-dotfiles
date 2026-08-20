{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.programs.shotcut;
in
{
  options.my.programs.shotcut.enable = lib.mkEnableOption "video editor";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      shotcut
    ];
  };
}
