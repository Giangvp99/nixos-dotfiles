{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.hardware.storageHealth;
in
{
  options.my.hardware.storageHealth = {
    enable = lib.mkEnableOption "SSD maintenance and storage diagnostics";

    enableSmartd = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable SMART disk monitoring daemon.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.fstrim.enable = true;

    services.smartd.enable = cfg.enableSmartd;

    environment.systemPackages = with pkgs; [
      smartmontools
      nvme-cli
      hdparm
    ];
  };
}
