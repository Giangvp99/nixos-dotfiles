{
  imports = [
    ./hardware.nix

    ../../profiles/nixos/common.nix
    ../../profiles/nixos/laptop.nix
    ../../profiles/nixos/plasma.nix

    ../../modules/nixos/services/brave-policy.nix
    ../../modules/nixos/services/flatpak.nix
    ../../modules/nixos/virtualization/docker.nix
  ];

  networking.hostName = "j4n9-hplaptop";

  my = {
    services = {
      bravePolicy.enable = true;
      flatpak.enable = true;
    };

    virtualization.docker = {
      enable = true;
      users = [ ]; #ntgiang
    };
  };

  system.stateVersion = "26.05";
}
