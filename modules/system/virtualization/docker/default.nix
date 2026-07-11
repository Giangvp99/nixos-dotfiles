{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.systemSettings.virtualization.docker;
  adminUsers = config.systemSettings.adminUsers;
in
{
  options = {
    systemSettings.virtualization.docker = {
      enable = lib.mkEnableOption "Enable docker";

      addUsersToDockerGroup = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Add admin users to docker group. This is root-equivalent.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };
    users.users = lib.mkIf cfg.addUsersToDockerGroup (
      builtins.listToAttrs (
        map
          (user: {
            name = user;
            value = {
              extraGroups = [ "docker" ];
            };
          })
          adminUsers
      )
    );
    environment.systemPackages = with pkgs; [
      docker
      docker-compose
      lazydocker
    ];
  };
}
