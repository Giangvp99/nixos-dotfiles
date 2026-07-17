{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.core.nix;
in
{
  options.my.core.nix.enable = lib.mkEnableOption "the common Nix configuration";

  config = lib.mkIf cfg.enable {
    nix = {
      package = pkgs.nix;

      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        trusted-users = [
          "root"
          "@wheel"
        ];

        auto-optimise-store = true;
        download-buffer-size = 500000000;

        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
        ];

        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };

      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };

      optimise = {
        automatic = true;
        dates = [ "weekly" ];
      };
    };

    nixpkgs.config.allowUnfree = true;
  };
}
