{ config
, lib
, ...
}:

let
  cfg = config.my.services.avahi;
in
{
  options.my.services.avahi = {
    enable = lib.mkEnableOption "local network service discovery";

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open the firewall ports required by Avahi.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      inherit (cfg) openFirewall;
    };
  };
}
