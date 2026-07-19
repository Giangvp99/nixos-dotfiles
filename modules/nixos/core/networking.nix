{ config
, lib
, ...
}:

let
  cfg = config.my.core.networking;
in
{
  options.my.core.networking.enable =
    lib.mkEnableOption "NetworkManager networking";

  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;
  };
}
