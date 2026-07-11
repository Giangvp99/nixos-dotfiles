{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.systemSettings.scripts;
  dotfilesDir = config.systemSettings.dotfilesDir;

  j4n9 = pkgs.writeShellScriptBin "j4n9" ''
        set -euo pipefail

        HOST="j4n9-hplaptop"
        DOTFILES="${dotfilesDir}"

        case "''${1:-}" in
      test)
        sudo nixos-rebuild test --flake "$DOTFILES#$HOST"
        ;;
      switch)
        sudo nixos-rebuild switch --flake "$DOTFILES#$HOST"
        ;;
      boot)
        sudo nixos-rebuild boot --flake "$DOTFILES#$HOST"
        ;;
      rollback)
        sudo nixos-rebuild switch --rollback
        ;;
      update)
        cd "$DOTFILES"
        sudo nix flake update
        ;;
      fmt)
        cd "$DOTFILES"
        nix fmt
        ;;
      check)
        cd "$DOTFILES"
        nix flake check
        ;;
      doctor)
        echo "== Git status =="
        cd "$DOTFILES"
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
        sudo chown -R root:root "$DOTFILES"
        sudo chmod -R go-w "$DOTFILES"
        ;;
      unlock)
        sudo chown -R "$USER:users" "$DOTFILES"
        ;;
      *)
        echo "Usage: j4n9 {test|switch|boot|rollback|update|fmt|check|doctor|gc|optimise|lock|unlock}"
        exit 1
        ;;
    esac
  '';
in
{
  options.systemSettings.scripts = {
    enable = lib.mkEnableOption "Enable helper scripts";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      j4n9
    ];
  };
}
