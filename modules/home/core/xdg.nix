{ config
, lib
, ...
}:

let
  cfg = config.my.core.xdg;
  home = config.home.homeDirectory;
in
{
  options.my.core.xdg.enable =
    lib.mkEnableOption "XDG directories and MIME applications";

  config = lib.mkIf cfg.enable {
    xdg = {
      enable = true;

      userDirs = {
        enable = true;
        createDirectories = true;

        music = "${home}/Media/Music";
        videos = "${home}/Media/Videos";
        pictures = "${home}/Media/Pictures";
        templates = "${home}/Templates";
        download = "${home}/Downloads";
        documents = "${home}/Documents";

        desktop = null;
        publicShare = null;

        extraConfig = {
          XDG_DOTFILES_DIR = "${home}/.dotfiles";
          XDG_ARCHIVE_DIR = "${home}/Archive";
          XDG_PROJECTS_DIR = "${home}/Projects";
          XDG_CLOUD_DIR = "${home}/Drive";
          XDG_BOOK_DIR = "${home}/Media/Books";
          XDG_VM_DIR = "${home}/Machines";
          XDG_NOTES_DIR = "${home}/Notes";
          XDG_SCREENSHOT_DIR = "${home}/Screenshots";
        };
      };

      mime.enable = true;
      mimeApps.enable = true;
    };
  };
}
