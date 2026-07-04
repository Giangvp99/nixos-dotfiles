{ config, inputs, ... }:

{
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
  ];

  config = {
    home-manager.users = builtins.listToAttrs (
      map (user: {
        name = user;
        value = {
          imports = [
            ./home.nix
            (./. + "/home-${user}.nix")
            ../../modules/user
          ];
        };
      }) config.systemSettings.users
    );
  };
}
