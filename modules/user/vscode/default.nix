{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.userSettings.vscode;
in
{
  options = {
    userSettings.vscode = {
      enable = lib.mkEnableOption "Enable vscode";
    };
  };

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
