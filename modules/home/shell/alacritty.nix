{ config
, lib
, ...
}:

let
  cfg = config.my.shell.alacritty;
in
{
  options.my.shell.alacritty.enable =
    lib.mkEnableOption "Alacritty terminal";

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;

      settings.window.opacity = lib.mkForce 0.85;
    };
  };
}
