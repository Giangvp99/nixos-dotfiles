{ lib, ... }:
{
  config = {
    userSettings = {
      git.enable = lib.mkDefault true;
    };
  };
}
