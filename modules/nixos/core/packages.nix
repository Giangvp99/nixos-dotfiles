{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.core.packages;
in
{
  options.my.core.packages.enable =
    lib.mkEnableOption "essential system administration packages";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git
      vim
      wget
      curl
    ];
  };
}
