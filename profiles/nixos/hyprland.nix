{
  imports = [
    ../../modules/nixos/desktop/hyprland.nix
    ../../modules/nixos/desktop/stylix.nix
  ];

  my.desktop = {
    hyprland = {
      enable = true;
      withUWSM = true;
      xwayland = true;
    };
    stylix = {
      enable = true;
      theme = "gruvbox-dark-medium";
    };
  };
}
