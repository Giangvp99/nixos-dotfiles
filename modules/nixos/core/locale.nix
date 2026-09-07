{ config
, lib
, ...
}:

let
  cfg = config.my.core.locale;
in
{
  options.my.core.locale.enable = lib.mkEnableOption "locale and time-zone settings";

  config = lib.mkIf cfg.enable {
    time.timeZone = "Asia/Ho_Chi_Minh";

    services.timesyncd.enable = true;

    i18n = {
      defaultLocale = "en_US.UTF-8";

      extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };
    };
  };
}
