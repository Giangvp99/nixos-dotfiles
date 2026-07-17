{
  imports = [
    ../../modules/nixos/hardware/bluetooth.nix
    ../../modules/nixos/hardware/power.nix
    ../../modules/nixos/services/printing.nix
  ];

  my = {
    hardware = {
      bluetooth.enable = true;

      power = {
        enable = true;
        backend = "power-profiles-daemon";
      };
    };

    services.printing.enable = true;
  };
}
