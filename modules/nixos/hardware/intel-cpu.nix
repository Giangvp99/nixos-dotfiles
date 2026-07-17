{ config
, lib
, ...
}:

let
  cfg = config.my.hardware.intelCpu;
in
{
  options.my.hardware.intelCpu.enable =
    lib.mkEnableOption "Intel CPU support";

  config = lib.mkIf cfg.enable {
    hardware.cpu.intel.updateMicrocode =
      lib.mkDefault config.hardware.enableRedistributableFirmware;

    boot.kernelModules = [ "kvm-intel" ];
  };
}


# No need enable at this times....
