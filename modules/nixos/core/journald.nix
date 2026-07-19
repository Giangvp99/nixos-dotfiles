{ config
, lib
, ...
}:

let
  cfg = config.my.core.journald;
in
{
  options.my.core.journald.enable = lib.mkEnableOption "limited persistent journal usage";

  config = lib.mkIf cfg.enable {
    services.journald = {
      extraConfig = ''
        SystemMaxUse=200M
        SystemKeepFree=1G
        MaxRetentionSec=30day
        Compress=yes
        Seal=yes
      '';

      rateLimitBurst = 500;
      rateLimitInterval = "30s";
    };
  };
}
