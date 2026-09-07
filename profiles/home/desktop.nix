{
  imports = [
    ../../modules/home/desktop/vietnamese-input.nix

    ../../modules/home/programs/brave.nix
    ../../modules/home/programs/chrome.nix
    ../../modules/home/programs/keepass.nix
    ../../modules/home/programs/media.nix
    ../../modules/home/programs/onlyoffice.nix
    ../../modules/home/programs/telegram.nix
    ../../modules/home/programs/viber.nix
    ../../modules/home/programs/vscode.nix
    ../../modules/home/programs/yazi.nix
    ../../modules/home/programs/shotcut.nix

    ../../modules/home/programs/journalism-tools.nix
  ];

  my = {
    desktop.vietnameseInput.enable = true;

    programs = {
      brave = {
        enable = true;
        defaultBrowser = true;
      };
      chrome.enable = true;

      keepass.enable = true;
      media.enable = true;
      onlyoffice.enable = true;
      telegram.enable = true;
      viber.enable = true;
      vscode.enable = true;
      yazi.enable = true;
      shotcut.enable = true;

      journalismTools.enable = true;
    };
  };
}
