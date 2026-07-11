{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.systemSettings.maintenance;
  dotfilesDir = config.systemSettings.dotfilesDir;
in
{
  options.systemSettings.maintenance = {
    enable = lib.mkEnableOption "Enable maintenance timers";

    autoUpdateCheck = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run flake update and build test automatically, without switching.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git
      nix-output-monitor
    ];

    systemd.services.j4n9-update-check = lib.mkIf cfg.autoUpdateCheck {
      description = "Check whether NixOS flake updates build successfully";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        WorkingDirectory = dotfilesDir;
      };
      path = with pkgs; [
        git
        nix
        nixos-rebuild
      ];
      script = ''
        set -euo pipefail
        git diff --quiet || {
          echo "Dotfiles tree is dirty; refusing automatic update."
          exit 0
        }

        nix flake update
        nixos-rebuild build --flake ${dotfilesDir}#${config.networking.hostName}
      '';
    };

    systemd.timers.j4n9-update-check = lib.mkIf cfg.autoUpdateCheck {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "Sun 10:00";
        Persistent = true;
      };
    };
  };
}
