{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.desktop.hyprland;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # Terminal và trình quản lý tệp
      kitty
      kdePackages.dolphin
      kdePackages.ark
      kdePackages.kio-admin

      # GTK / icon fallback
      adwaita-icon-theme
      papirus-icon-theme

      # Thanh trạng thái và launcher
      waybar
      fuzzel

      # Hệ sinh thái Hyprland
      hyprlock
      hypridle
      hyprpaper

      # Thông báo
      mako

      # Ảnh chụp màn hình
      grim
      slurp
      swappy

      # Clipboard
      wl-clipboard
      cliphist

      # Điều khiển laptop
      brightnessctl
      playerctl
      pavucontrol

      # Mạng
      networkmanagerapplet

      # Kiểm tra Wayland
      wev
      wayland-utils
    ];
  };
}
