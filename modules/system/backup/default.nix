{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.systemSettings.backup;
in
{
  options.systemSettings.backup = {
    enable = lib.mkEnableOption "Enable local backup tooling";

    packagesOnly = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Only install backup tools, do not configure automatic jobs yet.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      restic
      borgbackup
      rclone
    ];
  };
}
