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
        SystemMaxUse=50M
        SystemMaxFiles=5
      '';

      rateLimitBurst = 500;
      rateLimitInterval = "30s";
    };
  };
}
