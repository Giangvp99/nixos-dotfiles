{ config
, lib
, ...
}:

let
  cfg = config.my.services.automount;
in
{
  options.my.services.automount.enable =
    lib.mkEnableOption "automatic mounting of removable devices";

  config = lib.mkIf cfg.enable {
    services.devmon.enable = true;
    services.gvfs.enable = true;
    services.udisks2.enable = true;
  };
}
