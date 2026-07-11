{ config
, lib
, ...
}:

let
  cfg = config.systemSettings.security.sshd;
in
{
  options.systemSettings.security.sshd = {
    enable = lib.mkEnableOption "Enable OpenSSH server";

    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "SSH public keys allowed to log in.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        X11Forwarding = false;
        AllowUsers = config.systemSettings.users;
      };
      openFirewall = false;
    };

    users.users = builtins.listToAttrs (
      map
        (user: {
          name = user;
          value.openssh.authorizedKeys.keys = cfg.authorizedKeys;
        })
        config.systemSettings.users
    );
  };
}
