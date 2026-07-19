{ config
, lib
, ...
}:

let
  cfg = config.my.desktop.input;
in
{
  options.my.desktop.input.enable =
    lib.mkEnableOption "desktop keyboard settings";

  config = lib.mkIf cfg.enable {
    services.xserver.xkb = {
      layout = "us";
      variant = "";
      options = "caps:escape";
    };
  };
}
