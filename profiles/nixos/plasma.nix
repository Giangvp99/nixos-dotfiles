{
  imports = [
    ../../modules/nixos/desktop/audio.nix
    ../../modules/nixos/desktop/input.nix
    ../../modules/nixos/desktop/plasma.nix
    ../../modules/nixos/desktop/stylix.nix

    ../../modules/nixos/services/automount.nix
    ../../modules/nixos/services/avahi.nix
  ];

  my = {
    desktop = {
      audio.enable = true;
      input.enable = true;
      plasma.enable = true;

      stylix = {
        enable = true;
        theme = "gruvbox-dark-medium";
      };
    };

    services = {
      automount.enable = true;
      # avahi.enable = true;
    };
  };
}
