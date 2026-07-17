{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.services.flatpak;
in
{
  options.my.services.flatpak.enable =
    lib.mkEnableOption "system Flatpak support";

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
