{ pkgs
, ...
}:
{
  imports = [
    ./hardware.nix

    ../../profiles/nixos/common.nix
    ../../profiles/nixos/hyprland.nix

    ../../modules/nixos/services/brave-policy.nix
  ];

  networking.hostName = "j4n9-proxmox";

  system.stateVersion = "26.05";
  services.spice-vdagentd.enable = true;

  my = {
    services = {
      bravePolicy.enable = true;
    };
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd start-hyprland";
      user = "greeter";
    };
  };
}
