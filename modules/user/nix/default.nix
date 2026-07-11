{ pkgs, ... }:

{
  config = {
    home.stateVersion = "26.05";
    home.packages = with pkgs; [ nixfmt nixdoc ];
  };
}
