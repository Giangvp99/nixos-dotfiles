{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.programs.keepass;
in
{
  options.my.programs.keepass.enable =
    lib.mkEnableOption "KeePassXC password management tools";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      keepassxc
      keepmenu
    ];
  };
}
