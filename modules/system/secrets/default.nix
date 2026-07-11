{ config
, lib
, ...
}:

let
  cfg = config.systemSettings.secrets;
in
{
  options.systemSettings.secrets = {
    enable = lib.mkEnableOption "Enable sops-nix secrets";
  };

  config = lib.mkIf cfg.enable {
    sops = {
      age.keyFile = "/var/lib/sops-nix/key.txt";
      defaultSopsFile = ../../../secrets/secrets.yaml;

      secrets = {
        example_key = { };
      };
    };
  };
}
