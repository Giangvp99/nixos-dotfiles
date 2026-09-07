{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.programs.nixvim;
in
{
  imports = [
    ./options.nix
    ./keymaps.nix
    ./ui.nix
    ./navigation.nix
    ./editing.nix
    ./completion.nix
    ./lsp.nix
    ./formatting.nix
    ./git.nix
  ];

  options.my.programs.nixvim = {
    enable = lib.mkEnableOption "a declarative Neovim environment with NixVim";
  };

  config = lib.mkIf cfg.enable {
    programs.nixvim = {
      enable = true;

      defaultEditor = true;

      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;

      enableMan = true;

      globals = {
        mapleader = " ";
        maplocalleader = "\\";
      };

      extraPackages = with pkgs; [
        # Tìm kiếm và thao tác tệp
        ripgrep
        fd

        # Clipboard Wayland, dùng được trên Plasma và Hyprland
        wl-clipboard

        # Git
        git
        lazygit

        # Formatter
        nixfmt
        stylua
        shfmt

        # Công cụ hệ thống
        tree-sitter
      ];

      extraConfigLuaPre = ''
        -- Giảm các thông báo không cần thiết khi khởi động.
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1
      '';

      extraConfigLuaPost = ''
        require("custom")
      '';
    };
    home.file.".config/nvim/lua/custom".source =
      config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dots/nvim";
  };
}
