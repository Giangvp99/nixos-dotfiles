{ config
, lib
, ...
}:

let
  cfg = config.my.programs.gpg;
in
{
  options.my.programs.gpg.enable =
    lib.mkEnableOption "GnuPG agent";

  config = lib.mkIf cfg.enable {
    programs.gpg.enable = true;

    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      enableZshIntegration = true;
    };
  };
}
