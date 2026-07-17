{ inputs }:

{ hostname
, system ? "x86_64-linux"
, users ? [ ]
, extraModules ? [ ]
,
}:

inputs.nixpkgs.lib.nixosSystem {
  inherit system;

  specialArgs = {
    inherit inputs hostname;
  };

  modules = [
    ../hosts/${hostname}

    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.stylix.nixosModules.stylix
  ]
  ++ users
  ++ extraModules;
}
