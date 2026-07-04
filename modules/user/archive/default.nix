{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.userSettings.archive;
in
{
  options = {
    userSettings.archive = {
      enable = lib.mkEnableOption "Enable archive";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      unzip
      zip
      p7zip
      unar
      xz
      gzip
      bzip2
      zstd
      gnutar
    ];
  };
}
