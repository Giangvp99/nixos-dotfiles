{
  description = "J4N9 NixOS Flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprlock = {
      url = "github:hyprwm/hyprlock/v0.9.5";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      stylix,
      plasma-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      lib = nixpkgs.lib;
      hosts = builtins.filter (x: x != null) (
        lib.mapAttrsToList (name: value: if (value == "directory") then name else null) (
          builtins.readDir ./hosts
        )
      );
    in
    {
      nixosConfigurations = builtins.listToAttrs (
        map (host: {
          name = host;
          value = lib.nixosSystem {
            inherit system;
            modules = [
              { config.networking.hostName = host; }
              # stylix.nixosModules.stylix
              (./hosts + "/${host}")
              ./modules/system
              home-manager.nixosModules.home-manager
              {
                home-manager.extraSpecialArgs = {
                  inherit pkgs;
                  inherit pkgs-unstable;
                  inherit inputs;
                };
              }
            ];
            specialArgs = {
              #  inherit pkgs;
              inherit inputs;
            };
          };
        }) hosts
      );
    };
}
