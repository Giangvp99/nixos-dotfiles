{ config
, lib
, ...
}:

let
  cfg = config.my.programs.nixvim;
in
{
  config = lib.mkIf cfg.enable {
    programs.nixvim.plugins = {
      treesitter = {
        enable = true;

        highlight.enable = true;
        indent.enable = true;
        folding.enable = true;

        grammarPackages =
          with config.programs.nixvim.plugins.treesitter.package.builtGrammars;
          [
            bash
            json
            lua
            markdown
            nix
            regex
            toml
            vim
            vimdoc
            xml
            yaml
          ];
      };

      treesitter-context = {
        enable = true;

        settings = {
          max_lines = 3;
          multiline_threshold = 2;
          trim_scope = "outer";
        };
      };

      nvim-autopairs.enable = true;

      comment.enable = true;

      vim-surround.enable = true;

      todo-comments = {
        enable = true;

        settings = {
          signs = true;

          keywords = {
            FIX = {
              icon = " ";
            };

            TODO = {
              icon = " ";
            };

            WARN = {
              icon = " ";
            };

            NOTE = {
              icon = " ";
            };
          };
        };
      };

      flash.enable = true;
    };

    programs.nixvim.keymaps = [
      {
        mode = [
          "n"
          "x"
          "o"
        ];
        key = "s";
        action = "<cmd>lua require('flash').jump()<cr>";
        options = {
          desc = "Nhảy nhanh";
          silent = true;
        };
      }
    ];
  };
}
