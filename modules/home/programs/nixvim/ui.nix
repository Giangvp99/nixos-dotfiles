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
      # colorschemes.gruvbox = {
      #   enable = true;

      #   settings = {
      #     contrast = "hard";
      #     transparent_mode = false;
      #   };
      # };

      plugins = {
        lualine = {
          enable = true;

          settings = {
            options = {
              globalstatus = true;
              icons_enabled = true;
              component_separators = {
                left = "│";
                right = "│";
              };
              section_separators = {
                left = "";
                right = "";
              };
            };
          };
        };

        bufferline = {
          enable = true;

          settings = {
            options = {
              diagnostics = "nvim_lsp";
              separator_style = "thin";
              show_buffer_close_icons = false;
              show_close_icon = false;
              always_show_bufferline = false;
            };
          };
        };

        which-key = {
          enable = true;

          settings = {
            delay = 300;

            spec = [
              {
                __unkeyed-1 = "<leader>f";
                group = "Tìm kiếm";
              }
              {
                __unkeyed-1 = "<leader>g";
                group = "Git";
              }
              {
                __unkeyed-1 = "<leader>l";
                group = "LSP";
              }
              {
                __unkeyed-1 = "<leader>b";
                group = "Buffer";
              }
              {
                __unkeyed-1 = "<leader>n";
                group = "NixOS";
              }
              {
                __unkeyed-1 = "<leader>d";
                group = "Chẩn đoán";
              }
            ];
          };
        };

        indent-blankline = {
          enable = true;

          settings = {
            indent.char = "│";
            scope.enabled = true;
          };
        };

        web-devicons.enable = true;

        dressing.enable = true;

        notify.enable = true;
      };
    };
  };
}
