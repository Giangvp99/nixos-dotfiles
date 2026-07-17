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
      coreutils
      util-linux
      systemd
    ];

    text = ''
      set -euo pipefail

      host=${lib.escapeShellArg config.networking.hostName}
      flake=${lib.escapeShellArg cfg.flakeDirectory}

      command="''${1:-}"

      case "$command" in
        build)
          sudo nixos-rebuild build --flake "$flake#$host"
          ;;

        test)
          sudo nixos-rebuild test --flake "$flake#$host"
          ;;

        switch)
          sudo nixos-rebuild switch --flake "$flake#$host"
          ;;

        boot)
          sudo nixos-rebuild boot --flake "$flake#$host"
          ;;

        rollback)
          sudo nixos-rebuild switch --rollback
          ;;

        update)
          cd "$flake"
          sudo nix flake update
          ;;

        fmt)
          cd "$flake"
          nix fmt
          ;;

        check)
          cd "$flake"
          nix flake check
          ;;

        doctor)
          cd "$flake"

          echo "== Git status =="
          git status --short

          echo
          echo "== Flake check =="
          nix flake check

          echo
          echo "== Disk usage =="
          df -h /

          echo
          echo "== Failed systemd units =="
          systemctl --failed || true

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

        lock)
          sudo chown -R root:root "$flake"
          sudo chmod -R go-w "$flake"
          ;;

        unlock)
          sudo chown -R "$USER:users" "$flake"
          ;;

        *)
          echo "Usage: nixosctl {build|test|switch|boot|rollback|update|fmt|check|doctor|gc|optimise|lock|unlock}"
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
