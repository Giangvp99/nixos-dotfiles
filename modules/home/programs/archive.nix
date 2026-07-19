{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.programs.archive;
in
{
  options = {
    my.programs.archive = {
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
