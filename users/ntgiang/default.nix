{ config
, inputs
, pkgs
, ...
}:

{
  users.users.ntgiang = {
    isNormalUser = true;
    description = "Nguyen Truong Giang";

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

    users.ntgiang = {
      imports = [
        inputs.plasma-manager.homeModules.plasma-manager
        ./home.nix
      ];
    };
  };
}
