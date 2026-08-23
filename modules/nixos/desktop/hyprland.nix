{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.desktop.hyprland;
in
{
  options.my.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland Wayland compositor";

    withUWSM = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run Hyprland through UWSM.";
    };

    xwayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable compatibility with X11 applications.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      inherit (cfg) withUWSM;

      xwayland.enable = cfg.xwayland;
    };

    programs.dconf.enable = true;

    security.polkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    environment.systemPackages = with pkgs; [
      kitty
      xdg-utils
      xdg-user-dirs
    ];
  };
}
