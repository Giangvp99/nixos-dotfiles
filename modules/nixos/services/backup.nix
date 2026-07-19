{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.services.backup;
in
{
  options.my.services.backup = {
    enable = lib.mkEnableOption "backup tooling";

    packagesOnly = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install backup tools without configuring backup jobs.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      restic
      borgbackup
      rclone
    ];

    assertions = [
      {
        assertion = cfg.packagesOnly;
        message = ''
          my.services.backup.packagesOnly=false is not implemented yet.
          Define a concrete backup job before disabling packagesOnly.
        '';
      }
    ];
  };
}
