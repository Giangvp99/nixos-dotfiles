{ config
, lib
, ...
}:

let
  cfg = config.my.hardware.firmware;
in
{
  options.my.hardware.firmware.enable =
    lib.mkEnableOption "firmware updates through fwupd";

  config = lib.mkIf cfg.enable {
    services.fwupd.enable = true;
  };
}
