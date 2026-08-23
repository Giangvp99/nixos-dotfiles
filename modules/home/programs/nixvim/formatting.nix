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
      plugins.conform-nvim = {
        enable = true;

        settings = {
          notify_on_error = true;

          formatters_by_ft = {
            nix = [
              "nixfmt"
            ];

            lua = [
              "stylua"
            ];

            sh = [
              "shfmt"
            ];

            bash = [
              "shfmt"
            ];
          };

          format_on_save = {
            timeout_ms = 1000;
            lsp_format = "fallback";
          };
        };
      };

      keymaps = [
        {
          mode = [
            "n"
            "v"
          ];
          key = "<leader>lf";
          action = "<cmd>lua require('conform').format({ async = true, lsp_format = 'fallback' })<cr>";
          options = {
            desc = "Định dạng";
            silent = true;
          };
        }
      ];
    };
  };
}
