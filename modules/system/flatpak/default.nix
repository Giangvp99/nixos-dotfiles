{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.systemSettings.flatpak;
in
{
  options.systemSettings.flatpak = {
    enable = lib.mkEnableOption "Enable system Flatpak support";
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        kdePackages.xdg-desktop-portal-kde
      ];
    };
  };
}
