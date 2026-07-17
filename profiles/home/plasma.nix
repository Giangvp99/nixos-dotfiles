{
  imports = [
    ../../modules/home/desktop/plasma.nix
    ../../modules/home/desktop/stylix-targets.nix
  ];

  my.desktop = {
    plasma.enable = true;
    stylixTargets.enable = true;
  };
}
