{ inputs
, config
, ...
}:
{
  imports = [
    inputs.nixvim.homeModules.nixvim

    ../../profiles/home/common.nix
    ../../profiles/home/hyprland.nix

    ../../modules/home/programs/brave.nix
  ];

  home = {
    username = "jj";
    homeDirectory = "/home/jj";
    stateVersion = "26.05";
  };

  programs.git.settings.user = {
    name = "Giangvp99";
    email = "truonggiangvp99@gmail.com";
  };

  my.programs.brave = {
    enable = true;
    defaultBrowser = true;
  };

  xdg.configFile."hypr/hyprland.lua".source =
    config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dots/hypr/hyprland.lua";
}
