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
        telescope = {
          enable = true;

          keymaps = {
            "<leader>ff" = {
              action = "find_files";
              options.desc = "Tìm tệp";
            };

            "<leader>fg" = {
              action = "live_grep";
              options.desc = "Tìm nội dung";
            };

            "<leader>fb" = {
              action = "buffers";
              options.desc = "Tìm buffer";
            };

            "<leader>fh" = {
              action = "help_tags";
              options.desc = "Tìm trợ giúp";
            };

            "<leader>fr" = {
              action = "oldfiles";
              options.desc = "Tệp đã mở";
            };

            "<leader>fc" = {
              action = "commands";
              options.desc = "Tìm lệnh";
            };

            "<leader>fk" = {
              action = "keymaps";
              options.desc = "Tìm phím tắt";
            };

            "<leader>fd" = {
              action = "diagnostics";
              options.desc = "Tìm chẩn đoán";
            };
          };

          extensions = {
            fzf-native.enable = true;
            file-browser.enable = true;
          };

          settings = {
            defaults = {
              layout_strategy = "horizontal";

              layout_config = {
                horizontal = {
                  preview_width = 0.55;
                };

                width = 0.90;
                height = 0.85;
              };

              sorting_strategy = "ascending";
              prompt_prefix = "  ";
              selection_caret = "➜ ";
            };
          };
        };

        neo-tree = {
          enable = true;

          settings = {
            close_if_last_window = true;
            enable_git_status = true;
            enable_diagnostics = true;

            filesystem = {
              filtered_items = {
                visible = false;
                hide_dotfiles = false;
                hide_gitignored = true;
              };

              follow_current_file.enabled = true;
              use_libuv_file_watcher = true;
            };

            window = {
              width = 35;
            };
          };
        };
      };

      keymaps = [
        {
          mode = "n";
          key = "<leader>e";
          action = "<cmd>Neotree toggle<cr>";
          options = {
            desc = "Bật/tắt cây thư mục";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>E";
          action = "<cmd>Neotree reveal<cr>";
          options = {
            desc = "Hiện tệp hiện tại trong cây";
            silent = true;
          };
        }
      ];
    };
  };
}
