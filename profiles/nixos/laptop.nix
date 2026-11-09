{
  imports = [
    ../../modules/nixos/hardware/bluetooth.nix
    ../../modules/nixos/hardware/power.nix
    ../../modules/nixos/hardware/storage-health.nix
    ../../modules/nixos/hardware/firmware.nix
    ../../modules/nixos/services/printing.nix
    ../../modules/nixos/scripts/touchpadAutoToggle.nix
    ../../modules/nixos/desktop/fonts.nix
  ];

  my = {
    hardware = {
      # bluetooth.enable = true; disable because plasma

      power = {
        enable = true;
        backend = "power-profiles-daemon";
      };

      storageHealth = {
        enable = true;
        enableSmartd = false;
      };

      firmware.enable = true;
    };
    desktop.fonts.enable = true;
    scripts.touchpadAutoToggle.enable = true;

    # services.printing.enable = true;
  };
}
