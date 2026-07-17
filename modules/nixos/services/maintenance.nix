{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.services.maintenance;
in
{
  options.my.services.maintenance = {
    enable = lib.mkEnableOption "system maintenance tooling";

    flakeDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/etc/nixos";
      description = "Directory containing the system flake.";
    };

    autoUpdateCheck = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Periodically update the lock file and test-build the system.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git
      nix-output-monitor
    ];

    systemd.services.nixos-update-check =
      lib.mkIf cfg.autoUpdateCheck {
        description = "Check whether NixOS flake updates build successfully";

        serviceConfig = {
          Type = "oneshot";
          User = "root";
          WorkingDirectory = cfg.flakeDirectory;
        };

        path = with pkgs; [
          git
          nix
          nixos-rebuild
        ];

        script = ''
          set -euo pipefail

          if ! git diff --quiet || ! git diff --cached --quiet; then
            echo "Configuration tree is dirty; skipping update check."
            exit 0
          fi

          nix flake update

          nixos-rebuild build \
            --flake "${cfg.flakeDirectory}#${config.networking.hostName}"
        '';
      };

    systemd.timers.nixos-update-check =
      lib.mkIf cfg.autoUpdateCheck {
        wantedBy = [ "timers.target" ];

        timerConfig = {
          OnCalendar = "Sun 10:00";
          Persistent = true;
        };
      };
  };
}
