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
      wl-clipboard
      cliphist
    ];

    systemd.user.services.cliphist-text = {
      Unit = {
        Description = "Clipboard history for text";
        PartOf = [
          "graphical-session.target"
        ];
        After = [
          "graphical-session.target"
        ];
      };

      Service = {
        ExecStart = ''
          ${pkgs.wl-clipboard}/bin/wl-paste \
            --type text \
            --watch \
            ${pkgs.cliphist}/bin/cliphist store
        '';

        Restart = "on-failure";
      };

      Install.WantedBy = [
        "graphical-session.target"
      ];
    };

    systemd.user.services.cliphist-image = {
      Unit = {
        Description = "Clipboard history for images";
        PartOf = [
          "graphical-session.target"
        ];
        After = [
          "graphical-session.target"
        ];
      };

      Service = {
        ExecStart = ''
          ${pkgs.wl-clipboard}/bin/wl-paste \
            --type image \
            --watch \
            ${pkgs.cliphist}/bin/cliphist store
        '';

        Restart = "on-failure";
      };

      Install.WantedBy = [
        "graphical-session.target"
      ];
    };
  };
}
