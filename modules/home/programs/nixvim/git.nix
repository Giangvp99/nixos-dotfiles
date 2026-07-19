{ config
, lib
, ...
}:

let
  cfg = config.my.programs.nixvim;
in
{
  config = lib.mkIf cfg.enable {
    programs.nixvim = {
      plugins = {
        gitsigns = {
          enable = true;

          settings = {
            signs = {
              add.text = "│";
              change.text = "│";
              delete.text = "_";
              topdelete.text = "‾";
              changedelete.text = "~";
              untracked.text = "┆";
            };

            current_line_blame = false;
          };
        };

        diffview.enable = true;

        fugitive.enable = true;
      };

      keymaps = [
        {
          mode = "n";
          key = "]h";
          action = "<cmd>Gitsigns next_hunk<cr>";
          options = {
            desc = "Thay đổi Git tiếp theo";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "[h";
          action = "<cmd>Gitsigns prev_hunk<cr>";
          options = {
            desc = "Thay đổi Git trước";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>gp";
          action = "<cmd>Gitsigns preview_hunk<cr>";
          options = {
            desc = "Xem thay đổi";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>gs";
          action = "<cmd>Gitsigns stage_hunk<cr>";
          options = {
            desc = "Đưa thay đổi vào stage";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>gr";
          action = "<cmd>Gitsigns reset_hunk<cr>";
          options = {
            desc = "Hoàn tác thay đổi";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>gb";
          action = "<cmd>Gitsigns blame_line<cr>";
          options = {
            desc = "Xem blame dòng";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>gd";
          action = "<cmd>DiffviewOpen<cr>";
          options = {
            desc = "Mở Diffview";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>gD";
          action = "<cmd>DiffviewClose<cr>";
          options = {
            desc = "Đóng Diffview";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>gg";
          action = "<cmd>terminal lazygit<cr>";
          options = {
            desc = "Mở LazyGit";
            silent = true;
          };
        }
      ];
    };
  };
}
