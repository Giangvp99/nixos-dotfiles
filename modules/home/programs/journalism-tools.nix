{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.programs.journalismTools;
in
{
  options.my.programs.journalismTools.enable =
    lib.mkEnableOption "tools for research and journalism workflows";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      exiftool
      imagemagick
      mediainfo
      ffmpeg
      pandoc
      qpdf
      ocrmypdf
      ripgrep
      fd
      fzf
      magic-wormhole
      onionshare
    ];
  };
}
