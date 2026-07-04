{ config, lib, ... }:

let
  office = config.userSettings.office;
in
{
  options = {
    userSettings.office = lib.mkOption {
      default = null;
      description = "Default office";
      type = lib.types.enum [
        "onlyoffice"
        null
      ];
    };
  };

  config = {
    userSettings.onlyoffice.enable = lib.mkIf (office == "onlyoffice") true;
  };
}
