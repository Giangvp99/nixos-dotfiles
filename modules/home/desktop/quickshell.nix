{ config
, lib
, pkgs
, inputs
, ...
}:

let
  cfg = config.my.desktop.quickshell;
  system = pkgs.stdenv.hostPlatform.system;
in
{
  options.my.desktop.quickshell = {
    enable = lib.mkEnableOption "Quickshell desktop shell";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.quickshell.packages.${system}.default
    ];

    xdg.configFile."quickshell".source =
      config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dots/quickshell";
  };
}
