{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.systemSettings.kernel;
in
{
  options.systemSettings.kernel = {
    enable = lib.mkEnableOption "Enable sane kernel, firmware and microcode settings";

    package = lib.mkOption {
      type = lib.types.enum [
        "stable"
        "latest"
        "lts"
      ];
      default = "stable";
      description = "Kernel package choice.";
    };

    intelCpu = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Intel CPU microcode.";
    };

    amdCpu = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable AMD CPU microcode.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelPackages =
      if cfg.package == "latest" then
        pkgs.linuxPackages_latest
      else if cfg.package == "lts" then
        pkgs.linuxPackages
      else
        pkgs.linuxPackages;

    # hardware.enableAllFirmware = true;
    hardware.enableRedistributableFirmware = true;

    hardware.cpu.intel.updateMicrocode = cfg.intelCpu;
    hardware.cpu.amd.updateMicrocode = cfg.amdCpu;

    boot.tmp.cleanOnBoot = true;

    boot.kernel.sysctl = {
      "kernel.sysrq" = 0;
      "kernel.kptr_restrict" = 2;
      "kernel.dmesg_restrict" = 1;
    };
  };
}
