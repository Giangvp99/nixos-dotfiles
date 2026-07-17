{ config
, lib
, ...
}:

let
  cfg = config.my.hardware.power;
in
{
  options.my.hardware.power = {
    enable = lib.mkEnableOption "laptop power management";

    backend = lib.mkOption {
      type = lib.types.enum [
        "power-profiles-daemon"
        "tlp"
      ];

      default = "power-profiles-daemon";

      description = "Power-management backend used on the laptop.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.power-profiles-daemon.enable =
      cfg.backend == "power-profiles-daemon";

    services.tlp.enable =
      cfg.backend == "tlp";
  };
}
