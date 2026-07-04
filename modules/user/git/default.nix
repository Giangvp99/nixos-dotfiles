{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  osConfig,
  ...
}:

let
  cfg = config.userSettings.git;
in
{
  options = {
    userSettings.git = {
      enable = lib.mkEnableOption "Enable git";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.git
      pkgs.git-extras
      pkgs.git-filter-repo
      pkgs-unstable.openssh
    ];
    programs.git.enable = true;
    programs.git.settings = {
      user = {
        name = config.userSettings.name;
        email = config.userSettings.email;
      };
      init.defaultBranch = "main";
      safe.directory = [
        osConfig.systemSettings.dotfilesDir
        # osConfig.systemSettings.secretsFlakeDir
        (config.home.homeDirectory + "/.cache/nix/tarball-cache")
      ];
    };
    programs.git.lfs.enable = true;
    services.ssh-agent.enable = true;
  };
}
