{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.programs.media;
in
{
  options.my.programs.media.enable =
    lib.mkEnableOption "media playback tools";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      vlc
      mpv
      ffmpeg
    ];
  };
}
