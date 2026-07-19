{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.hardware.kernel;
in
{
  options.my.hardware.kernel = {
    enable = lib.mkEnableOption "kernel and firmware configuration";

    package = lib.mkOption {
      type = lib.types.enum [
        "stable"
        "latest"
      ];

      default = "stable";
      description = "Kernel package branch.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelPackages =
      if cfg.package == "latest" then pkgs.linuxPackages_latest else pkgs.linuxPackages;

    hardware.enableRedistributableFirmware = true;

    boot.tmp.cleanOnBoot = true;

    boot.kernel.sysctl = {
      "kernel.sysrq" = 0;
      "kernel.kptr_restrict" = 2;
      "kernel.dmesg_restrict" = 1;
    };
  };
}
