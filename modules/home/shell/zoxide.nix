{ config
, lib
, ...
}:

let
  cfg = config.my.shell.zoxide;
in
{
  options.my.shell.zoxide.enable =
    lib.mkEnableOption "smart directory navigation with zoxide";

  config = lib.mkIf cfg.enable {
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;

      options = [
        "--cmd"
        "z"
      ];
    };
  };
}
