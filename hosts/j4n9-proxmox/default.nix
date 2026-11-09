{
  imports = [
    ./hardware.nix

    ../../profiles/nixos/common.nix
    ../../profiles/nixos/hyprland.nix
  ];

  networking.hostName = "j4n9-proxmox";

  system.stateVersion = "26.05";
}
