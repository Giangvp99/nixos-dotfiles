{ config
, inputs
, pkgs
, ...
}:

{
  users.users.jj = {
    isNormalUser = true;
    description = "JJ";

    extraGroups = [
      "wheel"
      "networkmanager"
      "input"
      "dialout"
      "video"
      "render"
    ];

    shell = pkgs.zsh;
    createHome = true;
  };

  programs.zsh.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    extraSpecialArgs = {
      inherit inputs;
      hostName = config.networking.hostName;
    };

    users.jj = {
      imports = [
        inputs.plasma-manager.homeModules.plasma-manager
        ./home.nix
      ];
    };
  };
}
