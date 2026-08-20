{
  imports = [
    ../../modules/nixos/desktop/hyprland.nix
  ];

  my.desktop.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland = true;
  };
}
