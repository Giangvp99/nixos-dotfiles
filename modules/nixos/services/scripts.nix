{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.services.scripts;

  nixosctl = pkgs.writeShellApplication {
    name = "nixosctl";

    runtimeInputs = with pkgs; [
      git
      nix
      nixos-rebuild
      nix-output-monitor
      nvd
      coreutils
      util-linux
      systemd
      gnugrep
    ];

    text = ''
            set -euo pipefail

            host=${lib.escapeShellArg config.networking.hostName}
            flake=${lib.escapeShellArg cfg.flakeDirectory}

            require_clean_tree() {
              cd "$flake"

              if ! git diff --quiet || ! git diff --cached --quiet; then
                echo "Configuration tree contains uncommitted changes."
                echo "Review them with: git status && git diff"
                exit 1
              fi
            }

            run_check() {
              cd "$flake"
              nix flake check --show-trace
            }

            command="''${1:-}"

            case "$command" in
              build)
                cd "$flake"

                sudo nixos-rebuild build \
                  --flake "$flake#$host" \
                  --log-format internal-json 2>&1 \
                  | nom --json
                ;;

              test)
                cd "$flake"
                run_check

                sudo nixos-rebuild test \
                  --flake "$flake#$host" \
                  --log-format internal-json 2>&1 \
                  | nom --json
                ;;

              switch)
                cd "$flake"
                run_check

                old_system=$(readlink -f /run/current-system)

                sudo nixos-rebuild switch \
                  --flake "$flake#$host" \
                  --log-format internal-json 2>&1 \
                  | nom --json

                new_system=$(readlink -f /run/current-system)

                echo
                echo "== System changes =="
                nvd diff "$old_system" "$new_system" || true
                ;;

              boot)
                cd "$flake"
                run_check

                sudo nixos-rebuild boot \
                  --flake "$flake#$host" \
                  --log-format internal-json 2>&1 \
                  | nom --json
                ;;

              rollback)
                sudo nixos-rebuild switch --rollback
                ;;

              update)
                cd "$flake"

                if ! git diff --quiet || ! git diff --cached --quiet; then
                  echo "Commit or discard current changes before updating."
                  exit 1
                fi

                cp flake.lock flake.lock.before-update

                if nix flake update && nix flake check --show-trace; then
                  rm -f flake.lock.before-update

                  echo
                  echo "Update succeeded."
                  echo "Review with: git diff flake.lock"
                  echo "Then apply with: nixosctl test"
                else
                  echo
                  echo "Update or validation failed; restoring previous lock file."
                  mv flake.lock.before-update flake.lock
                  exit 1
                fi
                ;;

              update-input)
                input="''${2:-}"

                if [ -z "$input" ]; then
                  echo "Usage: nixosctl update-input <input-name>"
                  exit 1
                fi

                cd "$flake"

                if ! git diff --quiet || ! git diff --cached --quiet; then
                  echo "Commit or discard current changes before updating."
                  exit 1
                fi

                cp flake.lock flake.lock.before-update

                if nix flake update "$input" && nix flake check --show-trace; then
                  rm -f flake.lock.before-update
                  echo "Updated input: $input"
                else
                  mv flake.lock.before-update flake.lock
                  echo "Update failed; previous lock file restored."
                  exit 1
                fi
                ;;

              fmt)
                cd "$flake"
                nix fmt
                ;;

              check)
                run_check
                ;;

              diff)
                current=$(readlink -f /run/current-system)
                candidate="$flake/result"

                if [ ! -e "$candidate" ]; then
                  echo "No ./result build found. Running build first."
                  sudo nixos-rebuild build --flake "$flake#$host"
                fi

                nvd diff "$current" "$candidate"
                ;;

              generations)
                sudo nix-env \
                  --list-generations \
                  --profile /nix/var/nix/profiles/system
                ;;

              logs)
                journalctl \
                  --boot \
                  --priority=warning \
                  --no-pager
                ;;

              failed)
                systemctl --failed
                ;;

              doctor)
                cd "$flake"

                echo "== Git status =="
                git status --short

                echo
                echo "== Flake metadata =="
                nix flake metadata --no-write-lock-file

                echo
                echo "== Flake check =="
                nix flake check --show-trace

                echo
                echo "== Root filesystem =="
                df -h /

                echo
                echo "== Boot filesystem =="
                df -h /boot || true

                echo
                echo "== Failed systemd units =="
                systemctl --failed || true

                echo
                echo "== High-priority journal messages =="
                journalctl \
                  --boot \
                  --priority=err \
                  --no-pager \
                  --lines=100 || true

                echo
                echo "== Nix store verify =="
                sudo nix store verify --all --no-trust || true
                ;;

              gc)
                sudo nix-collect-garbage --delete-older-than 14d
                nix-collect-garbage --delete-older-than 14d
                ;;

              optimise)
                sudo nix store optimise
                ;;

              *)
                cat <<'EOF'
      Usage:
        nixosctl build
        nixosctl test
        nixosctl switch
        nixosctl boot
        nixosctl rollback
        nixosctl update
        nixosctl update-input <input-name>
        nixosctl fmt
        nixosctl check
        nixosctl diff
        nixosctl generations
        nixosctl logs
        nixosctl failed
        nixosctl doctor
        nixosctl gc
        nixosctl optimise
      EOF
                exit 1
                ;;
            esac
    '';
  };
in
{
  options.my.services.scripts = {
    enable = lib.mkEnableOption "local NixOS administration helper";

    flakeDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/etc/nixos";
      description = "Directory containing the NixOS flake.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      nixosctl
    ];
  };
}
