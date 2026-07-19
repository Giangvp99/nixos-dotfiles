{ config
, lib
, ...
}:

let
  cfg = config.my.security.firewall;
in
{
  options.my.security.firewall = {
    enable = lib.mkEnableOption "the system firewall";

    allowSyncthing = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the TCP and UDP ports used by Syncthing.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = {
      enable = true;
      allowPing = true;

      allowedTCPPorts = lib.optionals cfg.allowSyncthing [
        22000
      ];

      allowedUDPPorts = lib.optionals cfg.allowSyncthing [
        22000
        21027
      ];
    };
  };
}
