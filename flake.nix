{
  description = "NixOS configuration for J4N9";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim.url = "github:nix-community/nixvim/nixos-26.05";
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , treefmt-nix
    , ...
    }:

    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      mkHost = import ./lib/mk-host.nix {
        inherit inputs;
      };

      treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
    in
    {
      formatter.${system} = treefmtEval.config.build.wrapper;

      checks.${system} = {
        formatting = treefmtEval.config.build.check self;
        j4n9-hplaptop =
          self.nixosConfigurations.j4n9-hplaptop.config.system.build.toplevel;
      };

      nixosConfigurations = {
        j4n9-hplaptop = mkHost {
          hostname = "j4n9-hplaptop";
          inherit system;

          users = [
            ./users/ntgiang
          ];

          extraModules = [
          ];
        };
      };
    };
}
