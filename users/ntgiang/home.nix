{ inputs
, ...
}:
{
  imports = [
    inputs.nixvim.homeModules.nixvim

    ../../profiles/home/common.nix
    ../../profiles/home/desktop.nix
    ../../profiles/home/plasma.nix
  ];

  home = {
    username = "ntgiang";
    homeDirectory = "/home/ntgiang";
    stateVersion = "26.05";
  };

  programs.git.settings.user = {
    name = "Giangvp99";
    email = "truonggiangvp99@gmail.com";
  };
}
