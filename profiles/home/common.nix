{
  imports = [
    ../../modules/home/core/xdg.nix

    ../../modules/home/programs/archive.nix
    ../../modules/home/programs/git.nix
    ../../modules/home/programs/gpg.nix
    ../../modules/home/programs/yazi.nix

    ../../modules/home/shell/alacritty.nix
    ../../modules/home/shell/zsh.nix
  ];

  my = {
    core.xdg.enable = true;

    programs = {
      archive.enable = true;

      git = {
        enable = true;
        extraSafeDirectories = [
          "/etc/nixos"
        ];
      };

      gpg.enable = true;
      yazi.enable = true;
    };

    shell = {
      alacritty.enable = true;
      zsh.enable = true;
    };
  };

  programs.home-manager.enable = true;
}
