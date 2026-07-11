{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.systemSettings.security.base;
in
{
  options.systemSettings.security.base = {
    enable = lib.mkEnableOption "Enable base system hardening";
  };

  config = lib.mkIf cfg.enable {
    security.sudo = {
      enable = true;
      wheelNeedsPassword = true;
      extraConfig = ''
        Defaults timestamp_timeout=5
        Defaults passwd_timeout=1
        Defaults lecture=never
      '';
    };

    security.polkit.enable = true;

    services.dbus.implementation = "broker";

    programs.firejail = {
      enable = true;
      wrappedBinaries = {
        firefox = {
          executable = "${pkgs.firefox}/bin/firefox";
          profile = "${pkgs.firejail}/etc/firejail/firefox.profile";
        };
      };
    };

    environment.systemPackages = with pkgs; [
      firejail
      usbutils
      pciutils
      lsof
      file
    ];
  };
}
