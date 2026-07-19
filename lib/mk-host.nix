{ inputs }:

{ hostname
, system ? "x86_64-linux"
, users ? [ ]
, extraModules ? [ ]
,
}:
let
  pkgsUnstable = import inputs.nixpkgs-unstable {
    inherit system;
    config = {
      allowUnfree = true;
    };
  };
in
inputs.nixpkgs.lib.nixosSystem {
  inherit system;

  specialArgs = {
    inherit inputs hostname pkgsUnstable;
  };

  modules = [
    ../hosts/${hostname}

    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.stylix.nixosModules.stylix

    {
      home-manager.extraSpecialArgs = {
        inherit inputs pkgsUnstable;
      };
    }
  ]
  ++ users
  ++ extraModules;
}
