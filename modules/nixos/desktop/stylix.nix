{ config
, lib
, pkgs
, inputs
, ...
}:

let
  cfg = config.my.desktop.stylix;

  themesDir = inputs.self + "/themes";

  availableThemes =
    builtins.attrNames (
      lib.filterAttrs
        (_name: kind: kind == "directory")
        (builtins.readDir themesDir)
    );

  themeName =
    if builtins.elem cfg.theme availableThemes then
      cfg.theme
    else
      throw ''
        Unknown theme "${cfg.theme}".
        Available themes: ${lib.concatStringsSep ", " availableThemes}
      '';

  themePath = themesDir + "/${themeName}";
  theme = import themePath;
in
{
  options.my.desktop.stylix = {
    enable = lib.mkEnableOption "system-wide Stylix theming";

    theme = lib.mkOption {
      type = lib.types.str;
      default = "gruvbox-dark-medium";
      description = "Theme selected from the root themes directory.";
    };
  };

  config = lib.mkIf cfg.enable {
    stylix = {
      enable = true;
      autoEnable = false;

      inherit (theme) polarity;
      base16Scheme = theme;

      image = pkgs.fetchurl {
        url = theme.backgroundUrl;
        sha256 = theme.backgroundSha256;
      };

      fonts = {
        monospace = {
          name = "FiraCode Nerd Font";
          package = pkgs.nerd-fonts.fira-code;
        };

        serif = {
          name = "Fira Sans";
          package = pkgs.fira-sans;
        };

        sansSerif = {
          name = "Fira Sans";
          package = pkgs.fira-sans;
        };

        emoji = {
          name = "Twitter Color Emoji";
          package = pkgs.twitter-color-emoji;
        };
      };

      targets = {
        console.enable = true;
        chromium.enable = true;
      };
    };
  };
}
