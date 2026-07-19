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
      description = ''
        Periodically test flake updates in an isolated temporary copy.
        The live configuration repository is not modified.
      '';
    };

    updateCheckCalendar = lib.mkOption {
      type = lib.types.str;
      default = "Sun 10:00";
      description = "systemd calendar expression for update checks.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git
      nix-output-monitor
      nvd
    ];

    systemd.services.nixos-update-check =
      lib.mkIf cfg.autoUpdateCheck {
        description = "Test NixOS updates in an isolated temporary tree";

        serviceConfig = {
          Type = "oneshot";
          User = "root";
          PrivateTmp = true;
          Nice = 10;
          IOSchedulingClass = "idle";
        };

        path = with pkgs; [
          coreutils
          git
          nix
        ];

        script = ''
          set -euo pipefail

          source_dir=${lib.escapeShellArg cfg.flakeDirectory}
          host=${lib.escapeShellArg config.networking.hostName}

          if ! git -C "$source_dir" diff --quiet \
            || ! git -C "$source_dir" diff --cached --quiet; then
            echo "Live configuration tree is dirty; skipping update check."
            exit 0
          fi

          work_dir=$(mktemp -d)

          cleanup() {
            rm -rf "$work_dir"
          }

          trap cleanup EXIT

          cp -a "$source_dir/." "$work_dir/"
          chmod -R u+w "$work_dir"

          cd "$work_dir"

          echo "Updating temporary flake copy..."
          nix flake update

          echo "Building updated system..."
          nix build \
            ".#nixosConfigurations.$host.config.system.build.toplevel" \
            --no-link

          echo "Update check completed successfully."
          echo "Run 'nixosctl update' manually to update the live repository."
        '';
      };

    systemd.timers.nixos-update-check =
      lib.mkIf cfg.autoUpdateCheck {
        wantedBy = [
          "timers.target"
        ];

        timerConfig = {
          OnCalendar = cfg.updateCheckCalendar;
          Persistent = true;
          RandomizedDelaySec = "30m";
        };
      };
  };
}
