{ config
, lib
, ...
}:

let
  cfg = config.my.services.openssh;
in
{
  options.my.services.openssh = {
    enable = lib.mkEnableOption "the OpenSSH server";

    allowedUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Users allowed to log in through SSH.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the SSH port in the NixOS firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      inherit (cfg) openFirewall;

      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        X11Forwarding = false;

        AllowUsers = if cfg.allowedUsers == [ ] then null else cfg.allowedUsers;
      };
    };
  };
}
