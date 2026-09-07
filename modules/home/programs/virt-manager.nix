{ config
, lib
, ...
}:

let
  cfg = config.my.programs.virt-manager;
in
{
  options.my.programs.virt-manager.enable = lib.mkEnableOption "virt-manager user configuration";

  config = lib.mkIf cfg.enable {
    dconf.settings = {
      "org/virt-manager/virt-manager/connections" = {
        autoconnect = [ "qemu:///system" ];
        uris = [ "qemu:///system" ];
      };
    };
  };
}
