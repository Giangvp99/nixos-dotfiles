{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.programs.telegram;
in
{
  options.my.programs.telegram.enable =
    lib.mkEnableOption "Telegram Desktop";

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.telegram-desktop
    ];

    xdg.desktopEntries."org.telegram.desktop" = {
      name = "Telegram";
      genericName = "Ứng dụng nhắn tin";
      comment = "Telegram Desktop";
      icon = "telegram";
      terminal = false;
      exec = "Telegram -- %u";

      categories = [
        "Network"
        "InstantMessaging"
        "Chat"
      ];

      mimeType = [
        "x-scheme-handler/tg"
      ];

      settings = {
        StartupWMClass = "TelegramDesktop";
        DBusActivatable = "false";
        SingleMainWindow = "true";
      };
    };
  };
}
