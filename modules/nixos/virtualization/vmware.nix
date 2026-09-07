{ config
, lib
, ...
}:

let
  cfg = config.my.virtualization.vmware;
in
{
  options.my.virtualization.vmware = {
    enable = lib.mkEnableOption "VMware Workstation";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.vmware.host.enable = true;
  };
}
