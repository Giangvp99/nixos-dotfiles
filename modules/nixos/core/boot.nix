{ config
, lib
, ...
}:

let
  cfg = config.my.core.boot;
in
{
  options.my.core.boot.enable =
    lib.mkEnableOption "the common UEFI boot configuration";

  config = lib.mkIf cfg.enable {
    boot = {
      loader = {
        systemd-boot = {
          enable = true;
          editor = false;
          configurationLimit = 10;
        };

        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot";
        };
      };

      initrd = {
        systemd.enable = true;
        verbose = false;
      };

      plymouth.enable = true;

      kernelParams = [
        "quiet"
        "splash"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
      ];
    };
  };
}
