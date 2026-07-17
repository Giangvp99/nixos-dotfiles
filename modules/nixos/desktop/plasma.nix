{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.desktop.plasma;
in
{
  options.my.desktop.plasma.enable =
    lib.mkEnableOption "KDE Plasma desktop";

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };

    services.desktopManager.plasma6.enable = true;

    environment.systemPackages = with pkgs; [
      kdePackages.dolphin
      kdePackages.kate
    ];
  };
}
