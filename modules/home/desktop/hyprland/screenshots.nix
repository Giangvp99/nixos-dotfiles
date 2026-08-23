{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.desktop.hyprland;

  screenshotArea = pkgs.writeShellApplication {
    name = "screenshot-area";

    runtimeInputs = with pkgs; [
      grim
      slurp
      swappy
      wl-clipboard
      coreutils
    ];

    text = ''
      set -euo pipefail

      directory="$HOME/Pictures/Screenshots"
      mkdir -p "$directory"

      filename="$directory/$(date +%Y-%m-%d_%H-%M-%S).png"

      geometry="$(slurp)" || exit 0

      grim -g "$geometry" "$filename"

      wl-copy < "$filename"

      swappy -f "$filename"
    '';
  };

  screenshotOutput = pkgs.writeShellApplication {
    name = "screenshot-output";

    runtimeInputs = with pkgs; [
      grim
      slurp
      swappy
      wl-clipboard
      coreutils
    ];

    text = ''
      set -euo pipefail

      directory="$HOME/Pictures/Screenshots"
      mkdir -p "$directory"

      filename="$directory/$(date +%Y-%m-%d_%H-%M-%S).png"

      output="$(slurp -o)" || exit 0

      grim -g "$output" "$filename"

      wl-copy < "$filename"

      swappy -f "$filename"
    '';
  };
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      screenshotArea
      screenshotOutput
    ];
  };
}
