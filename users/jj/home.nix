{ inputs
, ...
}:
{
  imports = [
    inputs.nixvim.homeModules.nixvim

    ../../profiles/home/common.nix
    ../../profiles/home/hyprland.nix
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
}
