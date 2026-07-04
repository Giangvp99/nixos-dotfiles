{ config, lib, pkgs, ... }:
{
  config = {
    userSettings = {
      git.enable = lib.mkDefault true;
    };
  };
}
