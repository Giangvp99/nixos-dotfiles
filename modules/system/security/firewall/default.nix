{ config, lib, ... }:

let
  cfg = config.systemSettings.security.firewall;
in
{
  options = {
    systemSettings.security.firewall = {
      # TODO make this more granular and better :|
      enable = lib.mkEnableOption "Actvate firewall";

      allowSyncthing = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Open ports for Syncthing.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Firewall
    networking.firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts =
        lib.optionals cfg.allowSyncthing [
          22000
          21027
        ];
      allowedUDPPorts =
        lib.optionals cfg.allowSyncthing [
          22000
          21027
        ];
    };
  };
}
