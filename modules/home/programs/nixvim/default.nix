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
        -- Tô sáng nhanh phần vừa sao chép.
        vim.api.nvim_create_autocmd("TextYankPost", {
          callback = function()
            vim.highlight.on_yank({
              higroup = "IncSearch",
              timeout = 200,
            })
          end,
        })

        -- Quay lại vị trí con trỏ cuối cùng khi mở tệp.
        vim.api.nvim_create_autocmd("BufReadPost", {
          callback = function(event)
            local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
            local line_count = vim.api.nvim_buf_line_count(event.buf)

            if mark[1] > 0 and mark[1] <= line_count then
              pcall(
                vim.api.nvim_win_set_cursor,
                0,
                mark
              )
            end
          end,
        })

        -- Không tiếp tục chú thích tự động khi xuống dòng.
        vim.api.nvim_create_autocmd("FileType", {
          callback = function()
            vim.opt_local.formatoptions:remove({
              "c",
              "r",
              "o",
            })
          end,
        })
      '';
    };
  };
}
