{ config, lib, ... }:

let
  browser = config.userSettings.browser;
in
{
  options = {
    userSettings.browser = lib.mkOption {
      default = null;
      description = "Default browser";
      type = lib.types.enum [
        "brave"
        null
      ];
    };
  };

  config = {
    userSettings.brave.enable = lib.mkIf (browser == "brave") true;
  };
}
