{ lib
, ...
}:

{
  imports = [
    ./packages.nix
    ./session.nix
    ./waybar.nix
    ./hyprlock.nix
    ./hypridle.nix
    ./hyprpaper.nix
    ./mako.nix
    ./launcher.nix
    ./clipboard.nix
    ./screenshots.nix
  ];

  options.my.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland user environment";

    terminal = lib.mkOption {
      type = lib.types.str;
      default = "kitty";
      description = "Terminal command used by Hyprland.";
    };

    fileManager = lib.mkOption {
      type = lib.types.str;
      default = "dolphin";
      description = "File manager command.";
    };

    browser = lib.mkOption {
      type = lib.types.str;
      default = "brave";
      description = "Browser command.";
    };
  };

  # config = lib.mkIf cfg.enable {
  # xdg.configFile."hypr/hyprland.lua".source =
  #  ./config/hyprland.lua;
  # };
}
