{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.desktop.hyprland;
  waybarConfig = "/etc/nixos/dots/waybar/config.jsonc";
  waybarStyle = "/etc/nixos/dots/waybar/style.css";
in
{
  config = lib.mkIf cfg.enable {
    programs.waybar = {
      enable = true;

      systemd = {
        enable = true;
        targets = [ "graphical-session.target" ];
      };
    };
    home.file = {
      ".config/waybar/config.jsonc".source = config.lib.file.mkOutOfStoreSymlink waybarConfig;

      ".config/waybar/style.css".source = config.lib.file.mkOutOfStoreSymlink waybarStyle;
    };

    systemd.user.services.waybar-config-reload = {
      Unit = {
        Description = "Reload Waybar configuration on change";
        After = [ "waybar.service" ];
      };

      Service = {
        ExecStart = pkgs.writeShellScript "waybar-config-watcher" ''
          ${pkgs.inotify-tools}/bin/inotifywait \
            -m \
            -e close_write,move,create \
            /etc/nixos/dots/waybar |
          while read -r directory event file; do
            if [ "$file" = "config.jsonc" ]; then
              ${pkgs.procps}/bin/pkill -SIGUSR2 waybar
            fi
          done
        '';

        Restart = "always";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
