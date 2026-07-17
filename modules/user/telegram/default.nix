{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.userSettings.telegram;
in
{
  options = {
    userSettings.telegram = {
      enable = lib.mkEnableOption "Enable telegram";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.telegram-desktop ];
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
