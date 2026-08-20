{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.programs.brave;
in
{
  options.my.programs.brave = {
    enable = lib.mkEnableOption "Brave browser";

    defaultBrowser = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Set Brave as the default web browser.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.brave = {
      enable = true;
      package = pkgs.brave;
      extensions = [
        "mciiogijehkdemklbdcbfkefimifhecn"
      ];
    };

    xdg.mimeApps.defaultApplications = lib.mkIf cfg.defaultBrowser {
      "text/html" = [ "brave-browser.desktop" ];
      "x-scheme-handler/http" = [ "brave-browser.desktop" ];
      "x-scheme-handler/https" = [ "brave-browser.desktop" ];
      "x-scheme-handler/about" = [ "brave-browser.desktop" ];
      "x-scheme-handler/unknown" = [ "brave-browser.desktop" ];
    };

    home.sessionVariables = lib.mkIf cfg.defaultBrowser {
      BROWSER = "${pkgs.brave}/bin/brave";
      DEFAULT_BROWSER = "${pkgs.brave}/bin/brave";
    };

  };
}
