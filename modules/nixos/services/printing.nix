{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.services.printing;
in
{
  options.my.services.printing.enable = lib.mkEnableOption "printing support";

  config = lib.mkIf cfg.enable {
    services.printing.enable = true;

    environment.systemPackages = [
      pkgs.cups-filters
    ];
  };
}
