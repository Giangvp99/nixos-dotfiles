{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.security.hardening;
in
{
  options.my.security.hardening = {
    enable = lib.mkEnableOption "base system hardening";

    firejailFirefox = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Wrap Firefox with Firejail.";
    };
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
      enable = cfg.firejailFirefox;

      wrappedBinaries = lib.mkIf cfg.firejailFirefox {
        firefox = {
          executable = "${pkgs.firefox}/bin/firefox";
          profile = "${pkgs.firejail}/etc/firejail/firefox.profile";
        };
      };
    };

    environment.systemPackages = with pkgs; [
      usbutils
      pciutils
      lsof
      file
    ] ++ lib.optionals cfg.firejailFirefox [
      firejail
    ];
  };
}
