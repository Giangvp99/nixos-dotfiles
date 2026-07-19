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
        lsp = {
          enable = true;

          servers = {
            # Nix
            nil_ls = {
              enable = true;

              settings = {
                formatting.command = [
                  "nixfmt"
                ];
              };
            };

            # Lua và cấu hình Neovim
            lua_ls = {
              enable = true;

              settings = {
                Lua = {
                  completion.callSnippet = "Replace";

                  diagnostics.globals = [
                    "vim"
                  ];

                  workspace.checkThirdParty = false;

                  telemetry.enable = false;
                };
              };
            };

            # Shell
            bashls.enable = true;

            # JSON
            jsonls.enable = true;

            # YAML
            yamlls.enable = true;

            # Markdown
            marksman.enable = true;
          };
        };

        trouble = {
          enable = true;

          settings = {
            focus = true;
            auto_close = true;
          };
        };
      };

      diagnostic.settings = {
        virtual_text = {
          spacing = 4;
          prefix = "●";
        };

        signs = true;
        underline = true;
        update_in_insert = false;
        severity_sort = true;

        float = {
          border = "rounded";
          source = "if_many";
        };
      };

      keymaps = [
        {
          mode = "n";
          key = "gd";
          action = "<cmd>lua vim.lsp.buf.definition()<cr>";
          options = {
            desc = "Đi tới định nghĩa";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "gD";
          action = "<cmd>lua vim.lsp.buf.declaration()<cr>";
          options = {
            desc = "Đi tới khai báo";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "gr";
          action = "<cmd>Telescope lsp_references<cr>";
          options = {
            desc = "Tìm nơi tham chiếu";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "gi";
          action = "<cmd>Telescope lsp_implementations<cr>";
          options = {
            desc = "Tìm triển khai";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "K";
          action = "<cmd>lua vim.lsp.buf.hover()<cr>";
          options = {
            desc = "Thông tin ký hiệu";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>lr";
          action = "<cmd>lua vim.lsp.buf.rename()<cr>";
          options = {
            desc = "Đổi tên ký hiệu";
            silent = true;
          };
        }
        {
          mode = [
            "n"
            "v"
          ];
          key = "<leader>la";
          action = "<cmd>lua vim.lsp.buf.code_action()<cr>";
          options = {
            desc = "Hành động mã";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "[d";
          action = "<cmd>lua vim.diagnostic.goto_prev()<cr>";
          options = {
            desc = "Lỗi trước";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "]d";
          action = "<cmd>lua vim.diagnostic.goto_next()<cr>";
          options = {
            desc = "Lỗi sau";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>dd";
          action = "<cmd>Trouble diagnostics toggle<cr>";
          options = {
            desc = "Danh sách lỗi toàn dự án";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>db";
          action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
          options = {
            desc = "Lỗi trong tệp hiện tại";
            silent = true;
          };
        }
      ];
    };
  };
}
