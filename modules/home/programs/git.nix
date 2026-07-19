{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.programs.git;
in
{
  options.my.programs.git = {
    enable = lib.mkEnableOption "Git";

    extraSafeDirectories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional directories trusted by Git.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      git-extras
      git-filter-repo
    ];

    programs.git = {
      enable = true;

      lfs.enable = true;

      settings = {
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        pull.rebase = false;

        safe.directory =
          cfg.extraSafeDirectories
          ++ [
            "${config.home.homeDirectory}/.cache/nix/tarball-cache"
          ];
      };
    };
  };
}
