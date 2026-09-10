{
  imports = [
    ../../modules/home/desktop/hyprland
    ../../modules/home/desktop/quickshell.nix
  ];

  my.desktop = {
    hyprland = {
      enable = true;
      terminal = "kitty";
      fileManager = "dolphin";
      browser = "brave";
    };

    quickshell.enable = true;
  };
}
