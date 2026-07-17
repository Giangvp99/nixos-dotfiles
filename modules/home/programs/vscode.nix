{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.programs.vscode;
in
{
  options.my.programs.vscode.enable =
    lib.mkEnableOption "Visual Studio Code";

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode;

      profiles.default.extensions = with pkgs.vscode-extensions; [
        dracula-theme.theme-dracula
        vscodevim.vim
        yzhang.markdown-all-in-one
      ];
    };
  };
}
