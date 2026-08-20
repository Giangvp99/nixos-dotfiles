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
    home.packages = [
      pkgs.kdePackages.polkit-kde-agent-1
    ];

    systemd.user.services.polkit-kde-agent = {
      Unit = {
        Description = "KDE Polkit authentication agent";
        PartOf = [
          "graphical-session.target"
        ];
        After = [
          "graphical-session.target"
        ];
      };

      Service = {
        ExecStart = ''
          ${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1
        '';

        Restart = "on-failure";
      };

      Install.WantedBy = [
        "graphical-session.target"
      ];
    };

    home.sessionVariables = {
      NIXOS_OZONE_WL = "1";

      MOZ_ENABLE_WAYLAND = "1";

      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

      SDL_VIDEODRIVER = "wayland,x11";
      CLUTTER_BACKEND = "wayland";
    };
  };
}
