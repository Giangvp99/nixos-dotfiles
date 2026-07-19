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
      blink-cmp = {
        enable = true;

        setupLspCapabilities = true;

        settings = {
          keymap = {
            preset = "default";
          };

          appearance = {
            nerd_font_variant = "mono";
          };

          completion = {
            documentation = {
              auto_show = true;
              auto_show_delay_ms = 300;
            };

            menu = {
              border = "rounded";
            };
          };

          signature = {
            enabled = true;
          };

          sources = {
            default = [
              "lsp"
              "path"
              "snippets"
              "buffer"
            ];
          };

          fuzzy = {
            implementation = "prefer_rust_with_warning";
          };
        };
      };

      friendly-snippets.enable = true;
    };
  };
}
