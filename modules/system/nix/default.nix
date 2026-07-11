{ config
, lib
, pkgs
, ...
}:

{
  options = {
    systemSettings = {
      dotfilesDir = lib.mkOption {
        default = "/etc/nixos";
        description = "Absolute path to the dotfiles directory";
        type = lib.types.path;
      };
    };
  };
  config = {
    nix = {
      package = pkgs.nix;
      settings = {
        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
          "https://hyprland.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
        trusted-users = config.systemSettings.adminUsers ++ [ "@wheel" ];
        auto-optimise-store = true;
        download-buffer-size = 500000000;
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };
      optimise = {
        automatic = true;
        dates = "weekly";
      };
    };
    programs.nix-ld = {
      enable = true;
      #Include libstdc++ in the nix-ld profile
      libraries = with pkgs; [
        stdenv.cc.cc
        zlib
        fuse3
        icu
        nss
        openssl
        curl
        expat
        libx11
        vulkan-headers
        vulkan-loader
        vulkan-tools
      ];
    };
    system.stateVersion = "26.05";
  };
}
