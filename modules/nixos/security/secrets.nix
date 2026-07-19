{ config
, lib
, ...
}:

let
  cfg = config.my.security.secrets;
in
{
  options.my.security.secrets = {
    enable = lib.mkEnableOption "SOPS-managed secrets";

    defaultFile = lib.mkOption {
      type = lib.types.path;
      default = ../../../secrets/secrets.yaml;
      description = "Default encrypted SOPS file.";
    };

    ageKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/sops-nix/key.txt";
      description = "Path to the local age identity file.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      age.keyFile = cfg.ageKeyFile;
      defaultSopsFile = cfg.defaultFile;

      secrets.example_key = { };
    };
  };
}
