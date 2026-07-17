{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.virtualization.docker;
in
{
  options.my.virtualization.docker = {
    enable = lib.mkEnableOption "Docker";

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Users added to the docker group. Membership is effectively
        equivalent to root access.
      '';
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

    users.users = lib.genAttrs cfg.users (_: {
      extraGroups = [ "docker" ];
    });

    environment.systemPackages = with pkgs; [
      docker-compose
      lazydocker
    ];
  };
}
